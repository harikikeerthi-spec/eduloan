const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const universities = [
    // IITs
    { name: 'Indian Institute of Technology Madras (IITM)', city: 'Chennai', state: 'Tamil Nadu', type: 'Public', ranking: 1 },
    { name: 'Indian Institute of Technology Delhi (IITD)', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 2 },
    { name: 'Indian Institute of Technology Bombay (IITB)', city: 'Mumbai', state: 'Maharashtra', type: 'Public', ranking: 3 },
    { name: 'Indian Institute of Technology Kanpur (IITK)', city: 'Kanpur', state: 'Uttar Pradesh', type: 'Public', ranking: 4 },
    { name: 'Indian Institute of Technology Roorkee (IITR)', city: 'Roorkee', state: 'Uttarakhand', type: 'Public', ranking: 5 },
    { name: 'Indian Institute of Technology Kharagpur (IITKGP)', city: 'Kharagpur', state: 'West Bengal', type: 'Public', ranking: 6 },
    { name: 'Indian Institute of Technology Guwahati (IITG)', city: 'Guwahati', state: 'Assam', type: 'Public', ranking: 7 },
    { name: 'Indian Institute of Technology Hyderabad (IITH)', city: 'Hyderabad', state: 'Telangana', type: 'Public', ranking: 8 },
    { name: 'Indian Institute of Technology Indore (IITI)', city: 'Indore', state: 'Madhya Pradesh', type: 'Public', ranking: 9 },
    { name: 'Indian Institute of Technology (BHU) Varanasi', city: 'Varanasi', state: 'Uttar Pradesh', type: 'Public', ranking: 10 },
    { name: 'Indian Institute of Technology Dhanbad (ISM)', city: 'Dhanbad', state: 'Jharkhand', type: 'Public', ranking: 11 },
    { name: 'Indian Institute of Technology Gandhinagar', city: 'Gandhinagar', state: 'Gujarat', type: 'Public', ranking: 12 },
    { name: 'Indian Institute of Technology Ropar', city: 'Ropar', state: 'Punjab', type: 'Public', ranking: 13 },
    { name: 'Indian Institute of Technology Patna', city: 'Patna', state: 'Bihar', type: 'Public', ranking: 14 },
    { name: 'Indian Institute of Technology Mandi', city: 'Mandi', state: 'Himachal Pradesh', type: 'Public', ranking: 15 },
    { name: 'Indian Institute of Technology Jodhpur', city: 'Jodhpur', state: 'Rajasthan', type: 'Public', ranking: 16 },
    { name: 'Indian Institute of Technology Bhubaneswar', city: 'Bhubaneswar', state: 'Odisha', type: 'Public', ranking: 17 },
    { name: 'Indian Institute of Technology Tirupati', city: 'Tirupati', state: 'Andhra Pradesh', type: 'Public', ranking: 18 },
    { name: 'Indian Institute of Technology Palakkad', city: 'Palakkad', state: 'Kerala', type: 'Public', ranking: 19 },
    { name: 'Indian Institute of Technology Dharwad', city: 'Dharwad', state: 'Karnataka', type: 'Public', ranking: 20 },
    { name: 'Indian Institute of Technology Bhilai', city: 'Bhilai', state: 'Chhattisgarh', type: 'Public', ranking: 21 },
    { name: 'Indian Institute of Technology Goa', city: 'Farmagudi', state: 'Goa', type: 'Public', ranking: 22 },
    { name: 'Indian Institute of Technology Jammu', city: 'Jammu', state: 'Jammu and Kashmir', type: 'Public', ranking: 23 },

    // NITs
    { name: 'National Institute of Technology Trichy', city: 'Tiruchirappalli', state: 'Tamil Nadu', type: 'Public', ranking: 24 },
    { name: 'National Institute of Technology Karnataka (Surathkal)', city: 'Surathkal', state: 'Karnataka', type: 'Public', ranking: 25 },
    { name: 'National Institute of Technology Warangal', city: 'Warangal', state: 'Telangana', type: 'Public', ranking: 26 },
    { name: 'National Institute of Technology Calicut', city: 'Calicut', state: 'Kerala', type: 'Public', ranking: 27 },
    { name: 'National Institute of Technology Rourkela', city: 'Rourkela', state: 'Odisha', type: 'Public', ranking: 28 },
    { name: 'Malaviya National Institute of Technology Jaipur', city: 'Jaipur', state: 'Rajasthan', type: 'Public', ranking: 29 },
    { name: 'Visvesvaraya National Institute of Technology Nagpur', city: 'Nagpur', state: 'Maharashtra', type: 'Public', ranking: 30 },
    { name: 'Motilal Nehru National Institute of Technology Allahabad', city: 'Prayagraj', state: 'Uttar Pradesh', type: 'Public', ranking: 31 },
    { name: 'National Institute of Technology Kurukshetra', city: 'Kurukshetra', state: 'Haryana', type: 'Public', ranking: 32 },
    { name: 'National Institute of Technology Durgapur', city: 'Durgapur', state: 'West Bengal', type: 'Public', ranking: 33 },

    // BITS
    { name: 'BITS Pilani', city: 'Pilani', state: 'Rajasthan', type: 'Private', ranking: 34 },
    { name: 'BITS Pilani - Goa Campus', city: 'Zuarinagar', state: 'Goa', type: 'Private', ranking: 35 },
    { name: 'BITS Pilani - Hyderabad Campus', city: 'Hyderabad', state: 'Telangana', type: 'Private', ranking: 36 },

    // Private Universities
    { name: 'Vellore Institute of Technology (VIT) Vellore', city: 'Vellore', state: 'Tamil Nadu', type: 'Private', ranking: 37 },
    { name: 'SRM Institute of Science and Technology', city: 'Chennai', state: 'Tamil Nadu', type: 'Private', ranking: 38 },
    { name: 'Manipal Academy of Higher Education', city: 'Manipal', state: 'Karnataka', type: 'Private', ranking: 39 },
    { name: 'Thapar Institute of Engineering and Technology', city: 'Patiala', state: 'Punjab', type: 'Private', ranking: 40 },
    { name: 'Amity University Noida', city: 'Noida', state: 'Uttar Pradesh', type: 'Private', ranking: 41 },
    { name: 'Amity University Mumbai', city: 'Mumbai', state: 'Maharashtra', type: 'Private', ranking: 42 },
    { name: 'Lovely Professional University (LPU)', city: 'Phagwara', state: 'Punjab', type: 'Private', ranking: 43 },
    { name: 'Chandigarh University', city: 'Mohali', state: 'Punjab', type: 'Private', ranking: 44 },
    { name: 'Christ University', city: 'Bengaluru', state: 'Karnataka', type: 'Private', ranking: 45 },
    { name: 'Jain University', city: 'Bengaluru', state: 'Karnataka', type: 'Private', ranking: 46 },
    { name: 'Symbiosis International University', city: 'Pune', state: 'Maharashtra', type: 'Private', ranking: 47 },
    { name: 'Narsee Monjee Institute of Management Studies (NMIMS)', city: 'Mumbai', state: 'Maharashtra', type: 'Private', ranking: 48 },
    { name: 'Kalinga Institute of Industrial Technology (KIIT)', city: 'Bhubaneswar', state: 'Odisha', type: 'Private', ranking: 49 },
    { name: 'Shiv Nadar University', city: 'Dadri', state: 'Uttar Pradesh', type: 'Private', ranking: 50 },
    { name: 'Ashoka University', city: 'Sonipat', state: 'Haryana', type: 'Private', ranking: 51 },
    { name: 'Bennett University', city: 'Greater Noida', state: 'Uttar Pradesh', type: 'Private', ranking: 52 },
    { name: 'O.P. Jindal Global University', city: 'Sonipat', state: 'Haryana', type: 'Private', ranking: 53 },

    // Major State/Central Universities
    { name: 'University of Delhi', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 54 },
    { name: 'Jawaharlal Nehru University (JNU)', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 55 },
    { name: 'Banaras Hindu University (BHU)', city: 'Varanasi', state: 'Uttar Pradesh', type: 'Public', ranking: 56 },
    { name: 'Aligarh Muslim University (AMU)', city: 'Aligarh', state: 'Uttar Pradesh', type: 'Public', ranking: 57 },
    { name: 'Anna University', city: 'Chennai', state: 'Tamil Nadu', type: 'Public', ranking: 58 },
    { name: 'University of Mumbai', city: 'Mumbai', state: 'Maharashtra', type: 'Public', ranking: 59 },
    { name: 'Savitribai Phule Pune University', city: 'Pune', state: 'Maharashtra', type: 'Public', ranking: 60 },
    { name: 'Bangalore University', city: 'Bengaluru', state: 'Karnataka', type: 'Public', ranking: 61 },
    { name: 'University of Calcutta', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 62 },
    { name: 'University of Madras', city: 'Chennai', state: 'Tamil Nadu', type: 'Public', ranking: 63 },
    { name: 'Osmania University', city: 'Hyderabad', state: 'Telangana', type: 'Public', ranking: 64 },
    { name: 'Jawaharlal Nehru Technological University (JNTU) Hyderabad', city: 'Hyderabad', state: 'Telangana', type: 'Public', ranking: 65 },
    { name: 'Visvesvaraya Technological University (VTU)', city: 'Belagavi', state: 'Karnataka', type: 'Public', ranking: 66 },
    { name: 'Gujarat Technological University (GTU)', city: 'Ahmedabad', state: 'Gujarat', type: 'Public', ranking: 67 },
    { name: 'University of Rajasthan', city: 'Jaipur', state: 'Rajasthan', type: 'Public', ranking: 68 },
    { name: 'Lucknow University', city: 'Lucknow', state: 'Uttar Pradesh', type: 'Public', ranking: 69 },
    { name: 'Panjab University', city: 'Chandigarh', state: 'Chandigarh', type: 'Public', ranking: 70 },
    { name: 'Jadavpur University', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 71 },

    // Medical
    { name: 'All India Institute of Medical Sciences (AIIMS) Delhi', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 72 },
    { name: 'Christian Medical College (CMC) Vellore', city: 'Vellore', state: 'Tamil Nadu', type: 'Private', ranking: 73 },
    { name: 'JIPMER Puducherry', city: 'Puducherry', state: 'Puducherry', type: 'Public', ranking: 74 },
    { name: 'King Georges Medical University', city: 'Lucknow', state: 'Uttar Pradesh', type: 'Public', ranking: 75 },
    { name: 'St. Johns Medical College', city: 'Bengaluru', state: 'Karnataka', type: 'Private', ranking: 76 },
    { name: 'Maulana Azad Medical College', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 77 },
    { name: 'Armed Forces Medical College (AFMC)', city: 'Pune', state: 'Maharashtra', type: 'Public', ranking: 78 },

    // IIMs
    { name: 'Indian Institute of Management (IIM) Ahmedabad', city: 'Ahmedabad', state: 'Gujarat', type: 'Public', ranking: 79 },
    { name: 'Indian Institute of Management (IIM) Bangalore', city: 'Bengaluru', state: 'Karnataka', type: 'Public', ranking: 80 },
    { name: 'Indian Institute of Management (IIM) Calcutta', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 81 },
    { name: 'Indian Institute of Management (IIM) Lucknow', city: 'Lucknow', state: 'Uttar Pradesh', type: 'Public', ranking: 82 },
    { name: 'Indian Institute of Management (IIM) Indore', city: 'Indore', state: 'Madhya Pradesh', type: 'Public', ranking: 83 },
    { name: 'Indian Institute of Management (IIM) Kozhikode', city: 'Kozhikode', state: 'Kerala', type: 'Public', ranking: 84 },
    { name: 'FMS Delhi', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 85 },
    { name: 'XLRI Jamshedpur', city: 'Jamshedpur', state: 'Jharkhand', type: 'Private', ranking: 86 },
    { name: 'SPJIMR Mumbai', city: 'Mumbai', state: 'Maharashtra', type: 'Private', ranking: 87 },
    { name: 'Management Development Institute (MDI) Gurgaon', city: 'Gurugram', state: 'Haryana', type: 'Private', ranking: 88 },

    // Law
    { name: 'National Law School of India University (NLSIU)', city: 'Bengaluru', state: 'Karnataka', type: 'Public', ranking: 89 },
    { name: 'NALSAR University of Law', city: 'Hyderabad', state: 'Telangana', type: 'Public', ranking: 90 },
    { name: 'National Law University Delhi', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 91 },
    { name: 'West Bengal National University of Juridical Sciences', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 92 },

    // Specialized
    { name: 'Indian Institute of Science (IISc)', city: 'Bengaluru', state: 'Karnataka', type: 'Public', ranking: 93 },
    { name: 'Indian Statistical Institute (ISI) Kolkata', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 94 },
    { name: 'Tata Institute of Fundamental Research (TIFR)', city: 'Mumbai', state: 'Maharashtra', type: 'Public', ranking: 95 },
    { name: 'IISER Pune', city: 'Pune', state: 'Maharashtra', type: 'Public', ranking: 96 },
    { name: 'IISER Kolkata', city: 'Kolkata', state: 'West Bengal', type: 'Public', ranking: 97 },
    { name: 'NID Ahmedabad', city: 'Ahmedabad', state: 'Gujarat', type: 'Public', ranking: 98 },
    { name: 'NIFT Delhi', city: 'New Delhi', state: 'Delhi', type: 'Public', ranking: 99 },
    { name: 'TISS Mumbai', city: 'Mumbai', state: 'Maharashtra', type: 'Public', ranking: 100 },
];

async function seed() {
    console.log(`🚀 Starting comprehensive seeding of ${universities.length} Indian institutions...`);

    for (const uni of universities) {
        try {
            await prisma.university.upsert({
                where: {
                    name_country: {
                        name: uni.name,
                        country: 'India'
                    }
                },
                update: {
                    city: uni.city,
                    state: uni.state,
                    type: uni.type,
                    ranking: uni.ranking,
                    isFeatured: uni.ranking <= 20
                },
                create: {
                    name: uni.name,
                    country: 'India',
                    city: uni.city,
                    state: uni.state,
                    type: uni.type,
                    ranking: uni.ranking,
                    worldRanking: uni.ranking + 150, // Approximation
                    isFeatured: uni.ranking <= 20,
                    popularCourses: uni.type === 'Public' ? ['Engineering', 'Science'] : ['Management', 'Engineering', 'Commerce']
                }
            });
            process.stdout.write('.');
        } catch (e) {
            console.error(`\n❌ Error seeding ${uni.name}:`, e.message);
        }
    }

    console.log('\n✅ Comprehensive Indian university seeding completed!');
}

seed()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
