const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function verify() {
    console.log('🔍 Verifying seeded data...');

    const countryCount = await prisma.country.count();
    const countries = await prisma.country.findMany({ select: { name: true, flagUrl: true } });
    console.log(`🌍 Countries: ${countryCount}`);
    countries.forEach(c => console.log(`  - ${c.name}: ${c.flagUrl ? '✅ Flag present' : '❌ NO FLAG'}`));

    const mentorCount = await prisma.mentor.count();
    console.log(`👨‍🏫 Mentors: ${mentorCount}`);

    const eventCount = await prisma.communityEvent.count();
    console.log(`📅 Events: ${eventCount}`);

    const forumCount = await prisma.forumPost.count();
    console.log(`💬 Forum Posts: ${forumCount}`);

    const blogCount = await prisma.blog.count();
    console.log(`📝 Blogs: ${blogCount}`);

    await prisma.$disconnect();
}

verify().catch(console.error);
