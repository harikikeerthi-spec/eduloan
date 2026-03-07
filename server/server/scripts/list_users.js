
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const users = await prisma.user.findMany({
      select: {
        email: true,
        firstName: true,
        lastName: true,
      }
    });
    console.log('---USER_LIST_START---');
    console.log(JSON.stringify(users, null, 2));
    console.log('---USER_LIST_END---');
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
