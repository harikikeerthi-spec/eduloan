import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { GroqService } from './groq.service';

@Injectable()
export class UniversityShortlistService {
    constructor(
        private prisma: PrismaService,
        private groq: GroqService,
    ) { }

    private getFlagEmoji(countryCode: string): string {
        if (!countryCode || countryCode.length !== 2) return '🌐';
        return countryCode
            .toUpperCase()
            .split('')
            .map((char) => String.fromCodePoint(char.charCodeAt(0) + 127397))
            .join('');
    }

    async searchCountries(query: string) {
        const countries = await this.prisma.country.findMany({
            where: {
                OR: [
                    { name: { contains: query, mode: 'insensitive' } },
                    { code: { contains: query, mode: 'insensitive' } },
                ],
            },
            take: 10,
            orderBy: { popularForStudy: 'desc' },
        });

        const results = countries.map((c) => ({
            name: c.name,
            code: c.code,
            flag: this.getFlagEmoji(c.code),
        }));

        const trimmedQuery = query.trim();

        // If not enough results, fetch autocomplete from Groq
        if (trimmedQuery.length >= 2 && results.length < 5) {
            const prompt = `The user is searching for a country using the partial query "${trimmedQuery}".
             Please guess the full name of the country they are looking for. 
             Return a JSON list of up to 3 matches.
             Format: {"countries": [{"name": "Full Country Name", "code": "2-letter ISO Code"}]}`;

            try {
                const groqResult = await this.groq.getJson<{ countries: { name: string, code: string }[] }>(prompt);
                if (groqResult.countries && Array.isArray(groqResult.countries)) {
                    for (const c of groqResult.countries) {
                        if (!results.some(r => r.name.toLowerCase() === c.name.toLowerCase())) {
                            results.push({
                                name: c.name,
                                code: c.code || 'XX',
                                flag: this.getFlagEmoji(c.code || 'XX')
                            });
                        }
                    }
                }
            } catch (e) {
                // Ignore error
            }
        }

        if (trimmedQuery.length > 0) {
            const hasExactMatch = results.some(c => c.name.toLowerCase() === trimmedQuery.toLowerCase());
            if (!hasExactMatch) {
                results.unshift({
                    name: trimmedQuery,
                    code: 'XX',
                    flag: '🌐'
                });
            }
        }

        return {
            success: true,
            countries: results,
        };
    }

    async searchUniversities(query: string, degree?: string, country?: string) {
        const where: any = {
            OR: [
                { name: { contains: query, mode: 'insensitive' } },
                { city: { contains: query, mode: 'insensitive' } },
            ],
        };
        // If query matches country, it might bring too many results, but we keep it for flexibility.
        if (query) {
            where.OR.push({ country: { contains: query, mode: 'insensitive' } });
        }

        if (country) {
            where.country = { contains: country, mode: 'insensitive' };
        }

        const universities = await this.prisma.university.findMany({
            where,
            take: 10,
            orderBy: { isFeatured: 'desc' },
        });

        const results = universities.map((u) => ({
            name: u.name,
            country: u.country,
            location: u.city || u.country,
        }));

        const trimmedQuery = query.trim();

        // If not enough results, fetch autocomplete suggestions from Groq
        if (trimmedQuery.length >= 3 && results.length < 5) {
            const prompt = `The user is searching for a university or college using the partial query "${trimmedQuery}".
             Please guess the full name of the university they are looking for. 
             ${country ? `Focus on universities in ${country}.` : ''}
             Return a JSON list of up to 3 matches.
             Format: {"universities": [{"name": "Full University Name", "country": "Country", "location": "City, State or Country"}]}`;

            try {
                const groqResult = await this.groq.getJson<{ universities: any[] }>(prompt);
                if (groqResult.universities && Array.isArray(groqResult.universities)) {
                    for (const uni of groqResult.universities) {
                        if (!results.some(r => r.name.toLowerCase() === uni.name.toLowerCase())) {
                            results.push({
                                name: uni.name,
                                country: uni.country || country || 'Unknown',
                                location: uni.location || uni.country || 'Unknown'
                            });
                        }
                    }
                }
            } catch (e) {
                // Ignore error
            }
        }

        // Dynamic search: always include the user's exact query if not already in results
        if (trimmedQuery.length > 0) {
            const hasExactMatch = results.some(u => u.name.toLowerCase() === trimmedQuery.toLowerCase());
            if (!hasExactMatch) {
                results.unshift({
                    name: trimmedQuery,
                    country: country || 'Custom',
                    location: 'New Entry',
                });
            }
        }

        return {
            success: true,
            universities: results,
        };
    }

    async searchFields(query: string) {
        let fields: string[] = [];
        const trimmedQuery = query.trim();

        const prompt = `Provide a JSON list of 5-8 common academic fields or majors that match or are related to the query: "${query}".
    Return as: {"fields": ["Field 1", "Field 2", ...]}`;

        try {
            const result = await this.groq.getJson<{ fields: string[] }>(prompt);
            fields = result.fields || [];
        } catch (e) {
            fields = ['Computer Science', 'Business Administration', 'Data Science', 'Engineering', 'Public Health'];
        }

        if (trimmedQuery.length > 0 && !fields.some(f => f.toLowerCase() === trimmedQuery.toLowerCase())) {
            fields.unshift(trimmedQuery);
        }

        return { success: true, fields };
    }

    async searchCourses(university: string, query: string, degree: string) {
        let courses: { name: string }[] = [];
        const trimmedQuery = query.trim();
        const prompt = `Provide a JSON list of specific degree programs or courses offered at ${university} related to "${query}" for a ${degree} level.
    Return as: {"courses": [{"name": "Course Name 1"}, {"name": "Course Name 2"}, ...]}`;

        try {
            const result = await this.groq.getJson<{ courses: { name: string }[] }>(prompt);
            courses = result.courses || [];
        } catch (e) {
            courses = [{ name: `MS in ${query}` }, { name: `MA in ${query}` }];
        }

        if (trimmedQuery.length > 0 && !courses.some(c => c.name.toLowerCase() === trimmedQuery.toLowerCase())) {
            courses.unshift({ name: trimmedQuery });
        }

        return { success: true, courses };
    }

    async shortlist(profile: any) {
        const targetCountry = profile.country || profile.loan_country || profile.masters_country || profile.targetCountry;
        const countryRule = targetCountry
            ? `CRITICAL STRICT RULE: You MUST ONLY suggest universities located in ${targetCountry}. Do NOT suggest universities from any other country under any circumstances.`
            : `Suggest 5-8 specific universities across the globe.`;

        const prompt = `Based on the following student profile, suggest 5-8 specific universities.
    ${countryRule}
    Profile: ${JSON.stringify(profile)}

    Important: 
    - Include realistic "chance" of admission (High, Medium, Low).
    - Include rank, tuition, location, and a brief reason.
    - Provide high-quality descriptions.
    
    Today's date is ${new Date().toDateString()}. Provide realistic application deadlines for the upcoming intake cycles (e.g., Fall 2026, Spring 2027).

    IMPORTANT: For a "Study Abroad" context, strictly provide ONLY international (non-Indian) universities. Return "location" as "City, Country".
    
    Response MUST be valid JSON in this format:
    {
      "recommendations": [
        {
          "name": "Full University Name",
          "chance": "Admit Chance % (e.g. 85%)",
          "type": "Safe | Target | Ambitious",
          "rank": "QS World Rank (e.g. #42)",
          "tuition": "Annual Tuition (e.g. $ 33,000 or ₹ 8.0 L)",
          "location": "City, Country",
          "reason": "Specific strategic advice/fit analysis for this profile",
          "avgSalary": "Average Salary (e.g. $ 74,700/yr)",
          "deadline": "Upcoming Application Deadline (e.g. 15 Dec '26)",
          "flag": "Country Flag Emoji (e.g. 🇺🇸)",
          "country": "Country Name (e.g. USA)",
          "programName": "Specific Degree Program Name",
          "domain": "official institution domain (e.g. stanford.edu)",
          "logoUrl": "https://logo.clearbit.com/[domain]",
          "description": "Short program description (2-3 sentences)",
          "roi": "Estimated ROI percentage (e.g. 120%)",
          "acceptanceRate": "Acceptance rate percentage (e.g. 11%)",
          "duration": "Program duration (e.g. 12M or 24M)",
          "category": "e.g. STEM or Business",
          "indianCommunity": "Density of Indian students (Low | Medium | High)",
          "theRank": "Times Higher Education Rank (e.g. #18)",
          "costOfLiving": "Estimated annual living cost (e.g. $ 24,000)",
          "medianPackage": "Median salary package after graduation",
          "websiteUrl": "official university or program website URL",
          "universityType": "Public | Private",
          "genderRatio": "Male/Female split (e.g. 45% Male, 55% Female)",
          "studentTeacherRatio": "Ratio (e.g. 9:1)",
          "raceRatio": "Brief race/ethnicity breakdown",
          "safetyStatus": "Safety level (e.g. Highly Safe)",
          "academicFocus": "Core focus",
          "images": ["https://images.unsplash.com/photo-1541339907198-e08756ebafe3?q=80&w=1000", "https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=1000"],
          "admissionProcess": ["Step 1: Check Eligibility", "Step 2: Submit Application", "Step 3: Interview", "Step 4: Visa Process"],
          "testRequirements": {"GRE": "310+", "IELTS": "7.0+"}
        }
      ]
    }`;

        try {
            const result = await this.groq.getJson<any>(prompt);
            return { success: true, ...result };
        } catch (e) {
            console.error('Shortlist generation failed:', e);
            throw e;
        }
    }
}
