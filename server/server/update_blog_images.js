const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    console.log('Updating blog images...');

    // Update Complete Guide to Education Loans
    await prisma.blog.update({
        where: { slug: 'complete-guide-education-loans-2026' },
        data: {
            featuredImage: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&h=400&fit=crop',
            authorImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop'
        }
    });
    console.log('✓ Updated: Complete Guide to Education Loans');

    // Update Success Story
    await prisma.blog.update({
        where: { slug: 'success-story-small-town-to-stanford' },
        data: {
            featuredImage: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&h=400&fit=crop',
            authorImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop'
        }
    });
    console.log('✓ Updated: Success Story');

    console.log('\nDone! Both blogs now have unique images.');
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
