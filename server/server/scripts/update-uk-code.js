const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    await prisma.country.update({
        where: { code: 'UK' },
        data: { code: 'GB' }
    });
    console.log('Updated UK to GB');
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
