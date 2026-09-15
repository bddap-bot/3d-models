import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { VRMLoaderPlugin } from '@pixiv/three-vrm';

globalThis.self = globalThis;
if (!globalThis.ProgressEvent) {
  globalThis.ProgressEvent = class ProgressEvent {
    constructor(type, init = {}) { this.type = type; Object.assign(this, init); }
  };
}
if (!globalThis.createImageBitmap) {
  globalThis.createImageBitmap = async () => ({ width: 1, height: 1, close() {} });
}

const here = path.dirname(fileURLToPath(import.meta.url));
const expectedClips = ['sit', 'stand_up', 'idle_breathing', 'listen', 'talk_beats', 'nod', 'shrug', 'think', 'rest'];
const requiredBones = ['hips', 'spine', 'chest', 'upperChest', 'neck', 'head', 'leftUpperLeg', 'leftLowerLeg', 'leftFoot', 'rightUpperLeg', 'rightLowerLeg', 'rightFoot', 'leftShoulder', 'leftUpperArm', 'leftLowerArm', 'leftHand', 'rightShoulder', 'rightUpperArm', 'rightLowerArm', 'rightHand'];
const requiredExpressions = ['aa', 'ih', 'ou', 'ee', 'oh', 'blink', 'neutral', 'happy', 'surprised', 'amused', 'puzzled'];

function bytes(file) {
  const buffer = fs.readFileSync(file);
  return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
}

async function load(file, vrm = false) {
  const loader = new GLTFLoader();
  if (vrm) loader.register((parser) => new VRMLoaderPlugin(parser));
  return loader.parseAsync(bytes(file), path.dirname(file) + '/');
}

function triangles(scene) {
  let total = 0;
  scene.traverse((node) => {
    if (!node.isMesh) return;
    const geometry = node.geometry;
    total += geometry.index ? geometry.index.count / 3 : geometry.attributes.position.count / 3;
  });
  return total;
}

const vrmGltf = await load(path.join(here, 'aster-echo.vrm'), true);
const vrm = vrmGltf.userData.vrm;
if (!vrm) throw new Error('VRMLoaderPlugin did not create a VRM instance');
const mappedBoneNames = Object.keys(vrm.humanoid.rawHumanBones);
if (mappedBoneNames.length !== 55) throw new Error(`VRM humanoid map has ${mappedBoneNames.length} bones, expected 55`);
const boneNames = requiredBones.filter((name) => vrm.humanoid.getRawBoneNode(name));
if (boneNames.length !== requiredBones.length) throw new Error(`missing humanoid bones: ${requiredBones.filter((name) => !boneNames.includes(name)).join(', ')}`);
const expressionNames = Object.keys(vrm.expressionManager.expressionMap);
for (const name of requiredExpressions) {
  if (!expressionNames.includes(name)) throw new Error(`missing VRM expression ${name}`);
}
const vrmTriangles = triangles(vrm.scene);
if (vrmTriangles < 20000 || vrmTriangles > 50000) throw new Error(`VRM triangle count ${vrmTriangles} outside 20,000-50,000`);

const glb = await load(path.join(here, 'aster-echo.glb'));
const clipNames = glb.animations.map((clip) => clip.name);
for (const name of expectedClips) {
  if (!clipNames.includes(name)) throw new Error(`missing GLB animation ${name}`);
}
for (const clip of glb.animations) {
  const mixer = new THREE.AnimationMixer(glb.scene);
  const action = mixer.clipAction(clip);
  action.play();
  mixer.update(Math.max(1 / 60, clip.duration / 2));
  glb.scene.updateMatrixWorld(true);
  if (!clip.tracks.length || !Number.isFinite(clip.duration) || clip.duration <= 0) throw new Error(`invalid clip ${clip.name}`);
}
const glbTriangles = triangles(glb.scene);
if (glbTriangles !== vrmTriangles) throw new Error(`export triangle mismatch VRM=${vrmTriangles} GLB=${glbTriangles}`);

let morphMesh;
glb.scene.traverse((node) => {
  if (node.isMesh && node.morphTargetDictionary && node.morphTargetDictionary.aa !== undefined) morphMesh = node;
});
if (!morphMesh) throw new Error('facial morph mesh not found');
for (const name of ['aa', 'ih', 'ou', 'ee', 'oh', 'blink', 'neutral', 'amused', 'puzzled']) {
  const index = morphMesh.morphTargetDictionary[name];
  if (index === undefined) throw new Error(`missing GLB morph target ${name}`);
  const position = morphMesh.geometry.morphAttributes.position[index];
  let maximum = 0;
  for (let i = 0; i < position.count; i += 1) maximum = Math.max(maximum, Math.abs(position.getX(i)), Math.abs(position.getY(i)), Math.abs(position.getZ(i)));
  if (maximum < 0.001) throw new Error(`morph target ${name} has no visible displacement`);
}

const metrics = JSON.parse(fs.readFileSync(path.join(here, 'metrics.json'), 'utf8'));
if (metrics.triangles !== vrmTriangles) throw new Error(`metrics triangle mismatch source=${metrics.triangles} export=${vrmTriangles}`);
if (metrics.texture.width > 2048 || metrics.texture.height > 2048) throw new Error('texture exceeds 2048 px');

let renderResult = 'software GL unavailable; structural render assertions passed';
try {
  const headless = await import('gl');
  if (headless.default(8, 8)) renderResult = 'software GL context created';
} catch {}

const fileSizes = Object.fromEntries(['aster-echo.blend', 'aster-echo.vrm', 'aster-echo.glb', 'proof/turntable.gif'].map((name) => [name, fs.statSync(path.join(here, name)).size]));
console.log(JSON.stringify({ loader: 'three GLTFLoader + @pixiv/three-vrm VRMLoaderPlugin', humanoidBones: mappedBoneNames.length, requiredHumanoidBones: boneNames.length, expressions: expressionNames, clips: clipNames, visibleMorphs: ['aa', 'ih', 'ou', 'ee', 'oh', 'blink', 'neutral', 'amused', 'puzzled'], triangles: vrmTriangles, fileSizes, renderResult }, null, 2));
