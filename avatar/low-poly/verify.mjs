import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { AmbientLight, AnimationMixer, LoadingManager, PerspectiveCamera, Scene, WebGLRenderer } from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { VRMLoaderPlugin } from "@pixiv/three-vrm";

const here = path.dirname(fileURLToPath(import.meta.url));
const requiredBones = ["hips", "spine", "chest", "neck", "head", "leftUpperArm", "leftLowerArm", "leftHand", "rightUpperArm", "rightLowerArm", "rightHand", "leftUpperLeg", "leftLowerLeg", "leftFoot", "rightUpperLeg", "rightLowerLeg", "rightFoot"];
const requiredExpressions = ["aa", "ih", "ou", "ee", "oh", "blink", "neutral", "happy", "surprised", "amused", "puzzled"];
const requiredActions = ["sit", "stand_up", "idle_breathing", "listen", "talk_beats", "nod", "shrug", "think", "rest"];
const loopActions = ["idle_breathing", "listen", "talk_beats", "nod", "shrug", "think", "rest"];

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function sample(track, sampleIndex) {
  const size = track.getValueSize();
  return Array.from(track.values.slice(sampleIndex * size, (sampleIndex + 1) * size));
}

function distance(a, b, quaternion) {
  if (quaternion) {
    const dot = Math.abs(a.reduce((sum, value, index) => sum + value * b[index], 0));
    const length = Math.hypot(...a) * Math.hypot(...b);
    return 2 * Math.acos(Math.min(1, dot / length));
  }
  return Math.max(...a.map((value, index) => Math.abs(value - b[index])));
}

function trackDistance(track, firstIndex, secondIndex) {
  return distance(sample(track, firstIndex), sample(track, secondIndex), track.name.endsWith("quaternion"));
}

function assertAnimationQuality(gltf, file) {
  const clips = new Map(gltf.animations.map((clip) => [clip.name, clip]));
  for (const name of requiredActions) assert(clips.has(name), `${name} animation missing from ${file}`);
  for (const name of requiredActions) {
    const clip = clips.get(name);
    let motion = 0;
    let largestStep = 0;
    let movingTrack = null;
    for (const track of clip.tracks) {
      const samples = track.times.length;
      for (let index = 1; index < samples; index++) {
        const distanceFromStart = trackDistance(track, 0, index);
        if (distanceFromStart > motion) {
          motion = distanceFromStart;
          movingTrack = track;
        }
        largestStep = Math.max(largestStep, trackDistance(track, index - 1, index));
      }
    }
    assert(motion > 0.001, `${name} is static in ${file}`);
    assert(largestStep < Math.PI / 8, `${name} has a frame step over 22.5 degrees in ${file}`);
    const mixer = new AnimationMixer(gltf.scene);
    mixer.clipAction(clip).play();
    mixer.setTime(clip.duration * 0.47);
    gltf.scene.updateMatrixWorld(true);
    if (gltf.userData.vrm) {
      const [nodeName, property] = movingTrack.name.split(".");
      const node = gltf.scene.getObjectByName(nodeName);
      const before = node[property].toArray();
      gltf.userData.vrm.update(1 / 60);
      const after = node[property].toArray();
      assert(distance(before, after, property === "quaternion") < 0.0001, `${name} is overwritten by VRM update in ${file}`);
    }
    mixer.stopAllAction();
  }
  for (const name of loopActions) {
    for (const track of clips.get(name).tracks) {
      assert(trackDistance(track, 0, track.times.length - 1) < 0.0001, `${name}/${track.name} does not loop cleanly in ${file}`);
    }
  }
  const compareBoundary = (fromName, fromIndex, toName, toIndex) => {
    const from = clips.get(fromName);
    const to = new Map(clips.get(toName).tracks.map((track) => [track.name, track]));
    for (const fromTrack of from.tracks) {
      const toTrack = to.get(fromTrack.name);
      assert(toTrack, `${toName} lacks ${fromTrack.name} in ${file}`);
      const a = fromIndex < 0 ? fromTrack.times.length - 1 : fromIndex;
      const b = toIndex < 0 ? toTrack.times.length - 1 : toIndex;
      assert(distance(sample(fromTrack, a), sample(toTrack, b), fromTrack.name.endsWith("quaternion")) < 0.0001, `${fromName} to ${toName} pops at ${fromTrack.name} in ${file}`);
    }
  };
  compareBoundary("sit", -1, "stand_up", 0);
  compareBoundary("stand_up", -1, "sit", 0);
  return requiredActions.map((name) => ({ name, seconds: clips.get(name).duration, tracks: clips.get(name).tracks.length }));
}

async function load(name, expectVrm) {
  const bytes = await fs.readFile(path.join(here, name));
  const manager = new LoadingManager();
  const loader = new GLTFLoader(manager);
  loader.register((parser) => new VRMLoaderPlugin(parser, { autoUpdateHumanBones: !expectVrm }));
  const gltf = await loader.parseAsync(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), "");
  let triangles = 0;
  let morphTargets = [];
  let morphMesh = null;
  gltf.scene.traverse((node) => {
    if (!node.isMesh || !node.geometry) return;
    const geometry = node.geometry;
    triangles += geometry.index ? geometry.index.count / 3 : geometry.attributes.position.count / 3;
    if (node.morphTargetDictionary) {
      morphTargets = Object.keys(node.morphTargetDictionary);
      morphMesh = node;
    }
  });
  const animations = assertAnimationQuality(gltf, name);
  const result = { file: name, triangles, animations };
  assert(triangles <= 5000, `${name} has ${triangles} triangles`);
  for (const expression of ["aa", "ih", "ou", "ee", "oh", "blink", "neutral", "amused", "puzzled"]) {
    assert(morphTargets.includes(expression), `${expression} morph target missing from ${name}`);
  }
  const deformations = new Map();
  for (const expression of ["aa", "ih", "ou", "ee", "oh", "blink", "amused", "puzzled"]) {
    const index = morphMesh.morphTargetDictionary[expression];
    const values = morphMesh.geometry.morphAttributes.position[index].array;
    const magnitude = Array.from(values).reduce((sum, value) => sum + Math.abs(value), 0);
    assert(magnitude > 0.001, `${expression} has no geometric deformation in ${name}`);
    deformations.set(expression, Array.from(values));
  }
  const visemes = ["aa", "ih", "ou", "ee", "oh"];
  for (let left = 0; left < visemes.length; left++) {
    for (let right = left + 1; right < visemes.length; right++) {
      const a = deformations.get(visemes[left]);
      const b = deformations.get(visemes[right]);
      assert(a.some((value, index) => Math.abs(value - b[index]) > 0.001), `${visemes[left]} and ${visemes[right]} are not distinct in ${name}`);
    }
  }
  if (expectVrm) {
    const vrm = gltf.userData.vrm;
    assert(vrm, `${name} has no VRM 1.0 payload`);
    const bones = requiredBones.filter((bone) => vrm.humanoid.getRawBoneNode(bone));
    const expressions = Object.keys(vrm.expressionManager?.expressionMap ?? {});
    const missingBones = requiredBones.filter((bone) => !bones.includes(bone));
    const missingExpressions = requiredExpressions.filter((expression) => !expressions.includes(expression));
    assert(!missingBones.length, `missing humanoid bones: ${missingBones.join(", ")}`);
    assert(!missingExpressions.length, `missing expressions: ${missingExpressions.join(", ")}`);
    vrm.expressionManager.setValue("aa", 1);
    vrm.expressionManager.update();
    assert(morphMesh.morphTargetInfluences[morphMesh.morphTargetDictionary.aa] > 0.99, "aa expression did not deform the mesh");
    vrm.expressionManager.resetValues();
    vrm.expressionManager.update();
    assert(vrm.expressionManager.getValue("aa") === 0, "expression reset did not restore neutral");
    assert(morphMesh.morphTargetInfluences.every((value) => value === 0), "expression reset left morph influence behind");
    assert(vrm.humanoid.autoUpdateHumanBones === false, "raw animation clips require autoUpdateHumanBones=false");
    result.humanoidBones = bones;
    result.expressions = expressions;
  }
  return { gltf, result };
}

const loaded = [await load("lumen-relay.vrm", true), await load("lumen-relay.glb", false)];
let softwareFrame = "unavailable; scene graph, mixer playback, transitions, expressions, and structure asserted";
try {
  const module = await import("gl");
  const context = module.default(64, 64, { preserveDrawingBuffer: true });
  if (context) {
    const canvas = { width: 64, height: 64, style: {}, addEventListener() {}, removeEventListener() {}, getContext: () => context };
    const renderer = new WebGLRenderer({ canvas, context });
    const scene = new Scene();
    scene.add(loaded[0].gltf.scene, new AmbientLight(0xffffff, 2));
    const camera = new PerspectiveCamera(45, 1, 0.01, 100);
    camera.position.set(0, 0.9, 4);
    renderer.render(scene, camera);
    softwareFrame = "rendered 64x64 frame";
    renderer.dispose();
  }
} catch {}
for (const { result } of loaded) console.log(JSON.stringify(result));
console.log(`softwareGL=${softwareFrame}`);
