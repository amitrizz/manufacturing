const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function createPng(width, height, r, g, b, a = 255) {
  // PNG signature
  const signature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

  // IHDR chunk
  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData.writeUInt8(8, 8); // bit depth 8
  ihdrData.writeUInt8(6, 9); // color type 6 (RGBA)
  ihdrData.writeUInt8(0, 10); // compression method 0
  ihdrData.writeUInt8(0, 11); // filter method 0
  ihdrData.writeUInt8(0, 12); // interlace method 0
  const ihdrChunk = makeChunk('IHDR', ihdrData);

  // Raw image data: for each scanline, 1 filter byte (0) + width * 4 bytes (RGBA)
  const rowLength = 1 + width * 4;
  const rawData = Buffer.alloc(height * rowLength);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * rowLength;
    rawData[rowOffset] = 0; // No filter
    for (let x = 0; x < width; x++) {
      const pixelOffset = rowOffset + 1 + x * 4;
      rawData[pixelOffset] = r;
      rawData[pixelOffset + 1] = g;
      rawData[pixelOffset + 2] = b;
      rawData[pixelOffset + 3] = a;
    }
  }

  const compressedData = zlib.deflateSync(rawData);
  const idatChunk = makeChunk('IDAT', compressedData);

  // IEND chunk
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

function makeChunk(type, data) {
  const length = data.length;
  const chunk = Buffer.alloc(12 + length);
  chunk.writeUInt32BE(length, 0);
  chunk.write(type, 4, 4, 'ascii');
  data.copy(chunk, 8);

  // CRC32 of type + data
  const crcTarget = chunk.subarray(4, 8 + length);
  const crc = crc32(crcTarget);
  chunk.writeUInt32BE(crc, 8 + length);
  return chunk;
}

// Table-based CRC32
const crcTable = [];
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) {
    c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  }
  crcTable[n] = c >>> 0;
}

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

const assetsDir = path.join(__dirname, '..', 'assets');
if (!fs.existsSync(assetsDir)) {
  fs.mkdirSync(assetsDir, { recursive: true });
}

// Icon (blue background with manufacturing theme)
fs.writeFileSync(path.join(assetsDir, 'icon.png'), createPng(1024, 1024, 21, 101, 192)); // #1565C0
fs.writeFileSync(path.join(assetsDir, 'android-icon-foreground.png'), createPng(1024, 1024, 255, 255, 255, 255));
fs.writeFileSync(path.join(assetsDir, 'android-icon-background.png'), createPng(1024, 1024, 230, 244, 254)); // #E6F4FE
fs.writeFileSync(path.join(assetsDir, 'android-icon-monochrome.png'), createPng(1024, 1024, 255, 255, 255, 255));
fs.writeFileSync(path.join(assetsDir, 'splash.png'), createPng(1024, 1024, 21, 101, 192));
fs.writeFileSync(path.join(assetsDir, 'favicon.png'), createPng(48, 48, 21, 101, 192));

console.log('Generated app assets successfully in', assetsDir);
