const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkCounts() {
    try {
        const blogCount = await prisma.blog.count();
        const communityCount = await prisma.communityEvent.count();
        const universityCount = await prisma.university.count();
        const forumPostCount = await prisma.forumPost.count();
        const successStoryCount = await prisma.successStory.count();

        console.log('Database Record Counts:');
        console.log('- Blogs:', blogCount);
        console.log('- Community Events:', communityCount);
        console.log('- Universities:', universityCount);
        console.log('- Forum Posts:', forumPostCount);
        console.log('- Success Stories:', successStoryCount);

    } catch (e) {
        console.error('Error checking counts:', e);
    } finally {
        await prisma.$disconnect();
    }
}

checkCounts();
