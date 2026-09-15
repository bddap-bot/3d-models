import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));

function parseGlb(bytes) {
  if (bytes.toString("ascii", 0, 4) !== "glTF" || bytes.readUInt32LE(4) !== 2) throw new Error("invalid GLB");
  const jsonLength = bytes.readUInt32LE(12);
  const json = JSON.parse(bytes.toString("utf8", 20, 20 + jsonLength));
  const binaryOffset = 20 + jsonLength + 8;
  return { json, binary: bytes.subarray(binaryOffset, binaryOffset + bytes.readUInt32LE(20 + jsonLength)) };
}

function pad4(buffer, byte = 0) {
  const remainder = buffer.length % 4;
  return remainder ? Buffer.concat([buffer, Buffer.alloc(4 - remainder, byte)]) : buffer;
}

function animationChannels(document, animation) {
  const channels = new Map();
  for (const channel of animation.channels) {
    const node = document.nodes[channel.target.node]?.name;
    channels.set(`${node}:${channel.target.path}`, channel);
  }
  return channels;
}

const vrm = parseGlb(await fs.readFile(path.join(here, "lumen-relay.vrm")));
const source = parseGlb(await fs.readFile(path.join(here, "lumen-relay.glb")));
const chunks = [vrm.binary];
let binaryLength = vrm.binary.length;
const copiedAccessors = new Map();

function copyAccessor(sourceIndex) {
  if (copiedAccessors.has(sourceIndex)) return copiedAccessors.get(sourceIndex);
  const accessor = source.json.accessors[sourceIndex];
  const view = source.json.bufferViews[accessor.bufferView];
  const raw = source.binary.subarray(view.byteOffset ?? 0, (view.byteOffset ?? 0) + view.byteLength);
  const alignment = (4 - (binaryLength % 4)) % 4;
  if (alignment) {
    chunks.push(Buffer.alloc(alignment));
    binaryLength += alignment;
  }
  const newView = { buffer: 0, byteOffset: binaryLength, byteLength: raw.length };
  if (view.byteStride !== undefined) newView.byteStride = view.byteStride;
  vrm.json.bufferViews.push(newView);
  chunks.push(raw);
  binaryLength += raw.length;
  const newAccessor = { ...accessor, bufferView: vrm.json.bufferViews.length - 1 };
  vrm.json.accessors.push(newAccessor);
  const newIndex = vrm.json.accessors.length - 1;
  copiedAccessors.set(sourceIndex, newIndex);
  return newIndex;
}

for (const targetAnimation of vrm.json.animations ?? []) {
  const sourceAnimation = source.json.animations?.find((animation) => animation.name === targetAnimation.name);
  if (!sourceAnimation) throw new Error(`source animation missing: ${targetAnimation.name}`);
  const sourceChannels = animationChannels(source.json, sourceAnimation);
  for (const targetChannel of targetAnimation.channels) {
    const targetName = vrm.json.nodes[targetChannel.target.node]?.name;
    const key = `${targetName}:${targetChannel.target.path}`;
    const sourceChannel = sourceChannels.get(key);
    if (!sourceChannel) throw new Error(`source track missing: ${targetAnimation.name}/${key}`);
    const targetSampler = targetAnimation.samplers[targetChannel.sampler];
    const sourceSampler = sourceAnimation.samplers[sourceChannel.sampler];
    targetSampler.input = copyAccessor(sourceSampler.input);
    targetSampler.output = copyAccessor(sourceSampler.output);
    targetSampler.interpolation = sourceSampler.interpolation;
  }
}

const binary = pad4(Buffer.concat(chunks));
vrm.json.buffers[0].byteLength = binary.length;
const json = pad4(Buffer.from(JSON.stringify(vrm.json)), 0x20);
const output = Buffer.alloc(12 + 8 + json.length + 8 + binary.length);
output.write("glTF", 0, "ascii");
output.writeUInt32LE(2, 4);
output.writeUInt32LE(output.length, 8);
output.writeUInt32LE(json.length, 12);
output.write("JSON", 16, "ascii");
json.copy(output, 20);
const binaryHeader = 20 + json.length;
output.writeUInt32LE(binary.length, binaryHeader);
output.writeUInt32LE(0x004e4942, binaryHeader + 4);
binary.copy(output, binaryHeader + 8);
await fs.writeFile(path.join(here, "lumen-relay.vrm"), output);
console.log(`VRM_ANIMATIONS_REPAIRED=${vrm.json.animations.length}`);
