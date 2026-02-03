const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkBlogs() {
    const blogs = await prisma.blog.findMany({
        select: {
            id: true,
            title: true,
            featuredImage: true,
        }
    });

    console.log('Current blogs in database:');
    blogs.forEach(blog => {
        console.log(`\nTitle: ${blog.title}`);
        console.log(`Image: ${blog.featuredImage}`);
    });

    await prisma.$disconnect();
}

checkBlogs();
