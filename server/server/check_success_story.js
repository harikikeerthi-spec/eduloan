const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const blog = await prisma.blog.findUnique({
        where: { slug: 'success-story-small-town-to-stanford' },
        select: {
            title: true,
            slug: true,
            featuredImage: true,
            authorImage: true
        }
    });

    if (!blog) {
        console.log('Success Story blog not found!');
    } else {
        console.log('--- Success Story Blog ---');
        console.log('Title:', blog.title);
        console.log('Slug:', blog.slug);
        console.log('Featured Image:', blog.featuredImage);
        console.log('Author Image:', blog.authorImage);
        console.log('-------------------------');
    }
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
