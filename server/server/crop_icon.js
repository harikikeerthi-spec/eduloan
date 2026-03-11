const Jimp = require('jimp');

async function processIcon() {
    try {
        console.log('Loading image...');
        const image = await Jimp.read('../../assets/images/app_icon.png');
        console.log(`Original Size: ${image.bitmap.width}x${image.bitmap.height}`);

        // Autocrop the white background. (false indicates we want to leave the image as is if it fails, and tolerance is for almost-white pixels)
        image.autocrop({ tolerance: 0.05, cropOnlyFrames: false });
        console.log(`Cropped Size: ${image.bitmap.width}x${image.bitmap.height}`);

        // Now we make it a perfect square with some padding
        const size = Math.max(image.bitmap.width, image.bitmap.height);
        const paddedSize = Math.floor(size * 1.4); // Add 20% padding around the cropped logo

        const background = new Jimp(paddedSize, paddedSize, '#FFFFFF');

        const xOffset = Math.floor((paddedSize - image.bitmap.width) / 2);
        const yOffset = Math.floor((paddedSize - image.bitmap.height) / 2);

        background.composite(image, xOffset, yOffset);

        const outPath = '../../assets/images/app_icon_square.png';
        await background.writeAsync(outPath);
        console.log(`Saved squared icon to: ${outPath} (${paddedSize}x${paddedSize})`);
    } catch (e) {
        console.error('Error processing image:', e);
    }
}

processIcon();
