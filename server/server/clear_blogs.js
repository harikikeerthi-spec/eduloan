const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Deleting all existing blogs...');
    const deleted = await prisma.blog.deleteMany({});
    console.log(`Deleted ${deleted.count} blogs`);
    console.log('Database cleared!');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
