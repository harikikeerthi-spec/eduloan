
import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const columns = await prisma.$queryRaw`
      SELECT column_name, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'Comment'
    `;
    console.log('Comment table defaults:', JSON.stringify(columns, null, 2));
  } catch (e) {
    console.error('Error checking defaults:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
