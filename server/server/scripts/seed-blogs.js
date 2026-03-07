const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const sampleBlogs = [
    {
        title: 'Complete Guide to Education Loans in 2026: Everything You Need to Know',
        slug: 'complete-guide-education-loans-2026',
        excerpt: 'From understanding interest rates to navigating the application process, this comprehensive guide covers everything you need to know about education loans.',
        content: `
<h2>Introduction</h2>
<p>Pursuing higher education abroad is a dream for millions of students worldwide. However, the financial aspect can be daunting. Education loans have emerged as a vital tool for students looking to fund their international education without compromising on quality.</p>

<h2>Types of Education Loans</h2>
<h3>Secured Education Loans</h3>
<p>These loans require collateral such as property, fixed deposits, or other assets. They typically offer lower interest rates and higher loan amounts.</p>

<h3>Unsecured Education Loans</h3>
<p>No collateral required, but interest rates are usually higher. Ideal for students without significant assets.</p>

<h3>Government Education Loans</h3>
<p>Subsidized loans offered by government institutions with favorable terms and interest subsidies for economically weaker sections.</p>

<h2>Understanding Interest Rates</h2>
<p>Interest rates for education loans typically range from 8.5% to 12.5% per annum, depending on the lender and your profile.</p>

<h2>Required Documents</h2>
<ul>
<li>Admission letter from the university</li>
<li>Academic transcripts and certificates</li>
<li>Identity and address proof</li>
<li>Income proof of co-applicant</li>
<li>Property documents (for secured loans)</li>
</ul>

<h2>Application Process</h2>
<ol>
<li>Check eligibility with multiple lenders</li>
<li>Compare interest rates and terms</li>
<li>Submit application with required documents</li>
<li>Await verification and approval</li>
<li>Sign loan agreement and receive disbursement</li>
</ol>

<h2>Repayment Strategies</h2>
<p>Most education loans offer a moratorium period covering the study duration plus 6-12 months post-course. Plan your repayment strategy early to avoid financial stress.</p>

<h2>Conclusion</h2>
<p>Education loans are an investment in your future. With proper planning and understanding, you can navigate the process smoothly and focus on what matters most - your education.</p>
    `,
        category: 'Education Loans',
        authorName: 'Rajesh Kumar',
        authorRole: 'Senior Financial Advisor',
        authorImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop',
        featuredImage: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800&h=400&fit=crop',
        readTime: 8,
        isFeatured: true,
        isPublished: true,
        publishedAt: new Date('2026-01-15'),
    },
    {
        title: 'Top 10 Countries for International Students in 2026',
        slug: 'top-10-countries-international-students-2026',
        excerpt: 'Discover the best destinations for your international education journey, considering factors like quality of education, cost of living, and post-study work opportunities.',
        content: `
<h2>Introduction</h2>
<p>Choosing the right country for your international education is a crucial decision that impacts your career trajectory. Here's our comprehensive guide to the top destinations.</p>

<h2>1. United States</h2>
<p>Home to world-renowned universities like MIT, Stanford, and Harvard. Offers diverse programs and excellent research opportunities.</p>

<h2>2. United Kingdom</h2>
<p>Rich academic heritage with universities like Oxford and Cambridge. Shorter degree programs mean lower total costs.</p>

<h2>3. Canada</h2>
<p>Known for quality education at affordable costs. Excellent post-study work opportunities and immigration pathways.</p>

<h2>4. Australia</h2>
<p>Strong emphasis on research and innovation. Beautiful climate and high quality of life.</p>

<h2>5. Germany</h2>
<p>Many programs offered in English with low or no tuition fees. Strong economy with excellent job prospects.</p>

<h2>6. Netherlands</h2>
<p>Progressive education system with many English-taught programs. Central European location.</p>

<h2>7. Singapore</h2>
<p>Asian hub for education and business. World-class universities and multicultural environment.</p>

<h2>8. New Zealand</h2>
<p>Safe and welcoming environment. Quality education with a focus on practical learning.</p>

<h2>9. Ireland</h2>
<p>English-speaking country with a growing tech industry. Lower costs compared to the UK.</p>

<h2>10. France</h2>
<p>Rich culture and history. Many programs available in English with reasonable tuition fees.</p>

<h2>Conclusion</h2>
<p>Each country offers unique advantages. Consider your academic goals, budget, and career aspirations when making your decision.</p>
    `,
        category: 'Study Abroad',
        authorName: 'Priya Sharma',
        authorRole: 'Education Consultant',
        authorImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop',
        featuredImage: 'https://images.unsplash.com/photo-1488190211105-8b0e65b80b4e?w=800&h=400&fit=crop',
        readTime: 6,
        isFeatured: false,
        isPublished: true,
        publishedAt: new Date('2026-01-10'),
    },
];

async function main() {
    console.log('Seeding blogs...');

    for (const blog of sampleBlogs) {
        const existingBlog = await prisma.blog.findUnique({
            where: { slug: blog.slug },
        });

        if (!existingBlog) {
            await prisma.blog.create({ data: blog });
            console.log(`Created blog: ${blog.title}`);
        } else {
            console.log(`Blog already exists: ${blog.title}`);
        }
    }

    console.log('Seeding completed!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
