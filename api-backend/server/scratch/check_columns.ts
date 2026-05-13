
import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const columns = await prisma.$queryRaw`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'Comment'
    `;
    console.log('Comment table columns:', JSON.stringify(columns, null, 2));
  } catch (e) {
    console.error('Error checking columns:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
