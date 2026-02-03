const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Updating Success Story blog image...');

    const updated = await prisma.blog.update({
        where: { slug: 'success-story-small-town-to-stanford' },
        data: {
            featuredImage: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&h=400&fit=crop',
            authorImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop'
        }
    });

    console.log('Updated:', updated.title);
    console.log('New Featured Image:', updated.featuredImage);
    console.log('Done!');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
