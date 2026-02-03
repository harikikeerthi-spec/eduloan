const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const blogs = await prisma.blog.findMany({
        select: {
            title: true,
            slug: true,
            featuredImage: true,
            isPublished: true
        }
    });

    console.log('--- Blogs with Image Status ---');
    if (blogs.length === 0) {
        console.log('No blogs found.');
    } else {
        blogs.forEach((blog, index) => {
            const hasImage = blog.featuredImage ? '✓' : '✗';
            console.log(`${index + 1}. ${hasImage} ${blog.title}`);
            if (blog.featuredImage) {
                console.log(`   Image: ${blog.featuredImage.substring(0, 60)}...`);
            }
        });
    }
    console.log('-------------------------');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
