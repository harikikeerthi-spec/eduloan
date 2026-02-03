const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const blogs = await prisma.blog.findMany({
        select: {
            title: true,
            slug: true,
            isPublished: true
        }
    });

    console.log('--- Blogs in Database ---');
    if (blogs.length === 0) {
        console.log('No blogs found.');
    } else {
        blogs.forEach((blog, index) => {
            console.log(`${index + 1}. [${blog.isPublished ? 'Published' : 'Draft'}] ${blog.title} (${blog.slug})`);
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
