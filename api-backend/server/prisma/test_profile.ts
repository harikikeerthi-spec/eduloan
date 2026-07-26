import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Fetching all users with details...');
    const users = await prisma.user.findMany({
        select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            profileImage: true,
        }
    });

    console.log(`Found ${users.length} users:`);
    console.dir(users, { depth: null });
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
