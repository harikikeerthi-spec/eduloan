const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const countries = await prisma.country.findMany({
        select: { name: true, code: true }
    });
    console.log(JSON.stringify(countries, null, 2));
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
