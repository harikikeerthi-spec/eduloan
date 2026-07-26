import { Injectable, Logger } from '@nestjs/common';
import { OpenRouterService } from './openrouter.service';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class ShortlistingService {
  private readonly logger = new Logger(ShortlistingService.name);

  constructor(
    private readonly openRouterService: OpenRouterService,
    private readonly supabase: SupabaseService,
  ) {}

  popularCountries = [
    { name: 'USA', flag: '🇺🇸' },
    { name: 'UK', flag: '🇬🇧' },
    { name: 'Canada', flag: '🇨🇦' },
    { name: 'Australia', flag: '🇦🇺' },
    { name: 'Germany', flag: '🇩🇪' },
    { name: 'Ireland', flag: '🇮🇪' },
    { name: 'France', flag: '🇫🇷' },
    { name: 'Netherlands', flag: '🇳🇱' },
    { name: 'New Zealand', flag: '🇳🇿' },
    { name: 'Singapore', flag: '🇸🇬' },
    { name: 'Dubai (UAE)', flag: '🇦🇪' },
    { name: 'Italy', flag: '🇮🇹' },
    { name: 'Sweden', flag: '🇸🇪' },
    { name: 'Switzerland', flag: '🇨🇭' },
    { name: 'Spain', flag: '🇪🇸' },
  ];

  async searchCountries(query?: string) {
    if (!query) return this.popularCountries;
    return this.popularCountries.filter((c) =>
      c.name.toLowerCase().includes(query.toLowerCase()),
    );
  }

  async searchFields(query?: string) {
    const fields = [
      'Computer Science',
      'Data Science',
      'Business Analytics',
      'MBA',
      'Mechanical Engineering',
      'Electrical Engineering',
      'Civil Engineering',
      'Biotechnology',
      'Public Health',
      'Cybersecurity',
      'Artificial Intelligence',
      'Finance',
      'Marketing',
      'Architecture',
      'Psychology',
    ];
    if (!query) return fields;
    return fields.filter((f) => f.toLowerCase().includes(query.toLowerCase()));
  }

  async searchUniversities(query: string, degree: string, country?: string) {
    try {
      const prompt = `List 10 real universities/colleges matching '${query}' for ${degree} in ${country || 'any'}.
Include exact matches for specific names.
JSON array: [{"name": "Name", "country": "Country", "location": "City, State"}]`;
      const result = await this.openRouterService.getJson<any[]>(prompt);
      return Array.isArray(result) ? result : [];
    } catch (error) {
      this.logger.error('University search failed', error);
      return [];
    }
  }

  async searchCourses(university: string, query: string, degree: string) {
    try {
      const prompt = `Return a list of 10 real courses/programs matching '${query}' at ${university} for ${degree} degree.
Return ONLY a JSON array of strings or objects: ["Program Name"]`;
      const result = await this.openRouterService.getJson<any[]>(prompt);
      return Array.isArray(result) ? result : [];
    } catch (error) {
      this.logger.error('Course search failed', error);
      return [];
    }
  }

  async shortlist(profile: any, messages: any[] = []) {
    try {
      const systemPrompt = `You are an expert Study Abroad AI Consultant for VidyaLoan. Shortlist 5-6 top universities matching the student's profile.
IMPORTANT: Return ONLY a valid JSON object matching this exact structure:
{
  "recommendations": [
    {
      "name": "University Name",
      "chance": "High",
      "type": "Safe",
      "rank": "#15 Global",
      "tuition": "$45,000/yr",
      "location": "City, State",
      "country": "Country Name",
      "avgSalary": "$85,000/yr",
      "deadline": "Dec 15",
      "reason": "Brief 1-2 sentence reason for recommendation.",
      "programName": "Master of Science in CS",
      "logoUrl": "",
      "description": "Brief 1-2 sentence description.",
      "acceptanceRate": "15%",
      "duration": "2 Years",
      "roi": "High",
      "theRank": "#20 THE",
      "costOfLiving": "$15,000/yr",
      "websiteUrl": "https://..."
    }
  ]
}`;

      const userPrompt = `Profile: ${JSON.stringify(profile)}\nConversation History: ${JSON.stringify(messages)}`;

      const result = await this.openRouterService.getJson<{ recommendations: any[] }>(
        `${systemPrompt}\n\nStudent Request:\n${userPrompt}`
      );

      if (result && Array.isArray(result.recommendations) && result.recommendations.length > 0) {
        return result;
      }
    } catch (error) {
      this.logger.error('AI Shortlisting call failed, using fallback generator:', error);
    }

    // Fallback recommendation generator if AI call fails or times out
    return this.getFallbackShortlist(profile);
  }

  private getFallbackShortlist(profile: any) {
    const country = (profile?.country || 'USA').trim();
    const major = (profile?.major || 'Computer Science').trim();
    const gpa = profile?.gpa || '8.0';

    const sampleUniversities: Record<string, any[]> = {
      'USA': [
        {
          name: 'Northeastern University',
          chance: 'High',
          type: 'Target',
          rank: '#44 US News',
          tuition: '$54,000/yr',
          location: 'Boston, MA',
          country: 'USA',
          avgSalary: '$92,000/yr',
          deadline: 'Jan 15',
          reason: `Strong ${major} co-op program with high employment rates for international students.`,
          programName: `MS in ${major}`,
          logoUrl: 'https://logo.clearbit.com/northeastern.edu',
          description: 'Top research university renowned for experiential learning and co-op programs.',
          acceptanceRate: '18%',
          duration: '2 Years',
          roi: 'High',
          theRank: '#168 THE',
          costOfLiving: '$18,000/yr',
          websiteUrl: 'https://northeastern.edu'
        },
        {
          name: 'University of Texas at Dallas',
          chance: 'High',
          type: 'Safe',
          rank: '#115 US News',
          tuition: '$38,000/yr',
          location: 'Richardson, TX',
          country: 'USA',
          avgSalary: '$85,000/yr',
          deadline: 'Feb 1',
          reason: `Located in the Telecom Corridor tech hub, ideal match for CGPA ${gpa}.`,
          programName: `MS in ${major}`,
          logoUrl: 'https://logo.clearbit.com/utdallas.edu',
          description: 'Fast-growing public research university with excellent industry tie-ups.',
          acceptanceRate: '79%',
          duration: '2 Years',
          roi: 'High',
          theRank: '#351 THE',
          costOfLiving: '$12,000/yr',
          websiteUrl: 'https://utdallas.edu'
        },
        {
          name: 'Arizona State University',
          chance: 'High',
          type: 'Safe',
          rank: '#105 US News',
          tuition: '$34,000/yr',
          location: 'Tempe, AZ',
          country: 'USA',
          avgSalary: '$82,000/yr',
          deadline: 'Feb 15',
          reason: 'High acceptance rate with generous merit scholarships for international applicants.',
          programName: `MS in ${major}`,
          logoUrl: 'https://logo.clearbit.com/asu.edu',
          description: '#1 in Innovation, offering world-class labs and tech incubation.',
          acceptanceRate: '88%',
          duration: '2 Years',
          roi: 'High',
          theRank: '#182 THE',
          costOfLiving: '$13,000/yr',
          websiteUrl: 'https://asu.edu'
        },
        {
          name: 'University of Maryland, College Park',
          chance: 'Med',
          type: 'Ambitious',
          rank: '#46 US News',
          tuition: '$42,000/yr',
          location: 'College Park, MD',
          country: 'USA',
          avgSalary: '$98,000/yr',
          deadline: 'Dec 15',
          reason: 'Proximity to Washington D.C. tech & government research centers.',
          programName: `MS in ${major}`,
          logoUrl: 'https://logo.clearbit.com/umd.edu',
          description: 'Flagship public university known for groundbreaking research in STEM fields.',
          acceptanceRate: '44%',
          duration: '2 Years',
          roi: 'High',
          theRank: '#104 THE',
          costOfLiving: '$15,000/yr',
          websiteUrl: 'https://umd.edu'
        },
        {
          name: 'University of Illinois Chicago',
          chance: 'High',
          type: 'Target',
          rank: '#82 US News',
          tuition: '$31,000/yr',
          location: 'Chicago, IL',
          country: 'USA',
          avgSalary: '$88,000/yr',
          deadline: 'Feb 15',
          reason: 'Great urban campus in Chicago financial & tech ecosystem.',
          programName: `MS in ${major}`,
          logoUrl: 'https://logo.clearbit.com/uic.edu',
          description: 'Major public research university providing rich internship opportunities.',
          acceptanceRate: '78%',
          duration: '2 Years',
          roi: 'High',
          theRank: '#251 THE',
          costOfLiving: '$14,000/yr',
          websiteUrl: 'https://uic.edu'
        }
      ],
      'UK': [
        {
          name: 'University of Manchester',
          chance: 'Med',
          type: 'Target',
          rank: '#32 QS Global',
          tuition: '£28,000/yr',
          location: 'Manchester',
          country: 'UK',
          avgSalary: '£45,000/yr',
          deadline: 'Jan 31',
          reason: `Prestigious Russell Group university matching your CGPA ${gpa}.`,
          programName: `MSc in ${major}`,
          logoUrl: 'https://logo.clearbit.com/manchester.ac.uk',
          description: 'World-renowned institution with 25 Nobel laureates.',
          acceptanceRate: '27%',
          duration: '1 Year',
          roi: 'High',
          theRank: '#51 THE',
          costOfLiving: '£12,000/yr',
          websiteUrl: 'https://manchester.ac.uk'
        },
        {
          name: 'University of Birmingham',
          chance: 'High',
          type: 'Safe',
          rank: '#84 QS Global',
          tuition: '£26,000/yr',
          location: 'Birmingham',
          country: 'UK',
          avgSalary: '£42,000/yr',
          deadline: 'Feb 28',
          reason: 'Top targeted university by UK graduate employers.',
          programName: `MSc in ${major}`,
          logoUrl: 'https://logo.clearbit.com/bham.ac.uk',
          description: 'Red brick university offering cutting-edge research facilities.',
          acceptanceRate: '70%',
          duration: '1 Year',
          roi: 'High',
          theRank: '#101 THE',
          costOfLiving: '£11,000/yr',
          websiteUrl: 'https://birmingham.ac.uk'
        }
      ],
      'Germany': [
        {
          name: 'Technical University of Munich (TUM)',
          chance: 'Med',
          type: 'Ambitious',
          rank: '#37 QS Global',
          tuition: '€0 - €6,000/yr',
          location: 'Munich',
          country: 'Germany',
          avgSalary: '€62,000/yr',
          deadline: 'May 31',
          reason: 'Top engineering & tech university in Europe with minimal tuition.',
          programName: `MSc in ${major}`,
          logoUrl: 'https://logo.clearbit.com/tum.de',
          description: 'Germany\'s premier technical university located in Munich\'s tech hub.',
          acceptanceRate: '25%',
          duration: '2 Years',
          roi: 'Very High',
          theRank: '#30 THE',
          costOfLiving: '€11,000/yr',
          websiteUrl: 'https://tum.de'
        },
        {
          name: 'RWTH Aachen University',
          chance: 'High',
          type: 'Target',
          rank: '#106 QS Global',
          tuition: '€0/yr (Tuition Free)',
          location: 'Aachen',
          country: 'Germany',
          avgSalary: '€58,000/yr',
          deadline: 'Jul 15',
          reason: 'Zero tuition fee public university with elite industry partners.',
          programName: `MSc in ${major}`,
          logoUrl: 'https://logo.clearbit.com/rwth-aachen.de',
          description: 'Largest technical university in Germany, famous for engineering.',
          acceptanceRate: '50%',
          duration: '2 Years',
          roi: 'Very High',
          theRank: '#90 THE',
          costOfLiving: '€9,600/yr',
          websiteUrl: 'https://rwth-aachen.de'
        }
      ]
    };

    const recs = sampleUniversities[country] || sampleUniversities['USA'];
    return { recommendations: recs };
  }

  async saveShortlistChat(userId: string, messages: any[], recommendations?: any[]) {
    try {
      const payload: any = {
        userId,
        messages: messages || [],
        updatedAt: new Date().toISOString(),
      };
      if (recommendations && Array.isArray(recommendations) && recommendations.length > 0) {
        payload.recommendations = recommendations;
      }

      const { data, error } = await this.supabase.getClient()
        .from('UniversityShortlistChat')
        .upsert(payload, { onConflict: 'userId' })
        .select()
        .maybeSingle();

      if (error) {
        this.logger.error(`Failed to save shortlist chat for user ${userId}:`, error);
      }
      return data;
    } catch (error) {
      this.logger.error(`Failed to save shortlist chat for user ${userId}`, error);
      return null;
    }
  }

  async getLatestShortlistChat(userId: string) {
    try {
      const { data, error } = await this.supabase.getClient()
        .from('UniversityShortlistChat')
        .select('*')
        .eq('userId', userId)
        .maybeSingle();

      if (error) {
        this.logger.error(`Failed to get shortlist chat for user ${userId}:`, error);
        return null;
      }
      return data;
    } catch (error) {
      this.logger.error(`Failed to get shortlist chat for user ${userId}`, error);
      return null;
    }
  }

  async toggleFavoriteUniversity(userId: string, universityName: string, universityData: any) {
    try {
      const client = this.supabase.getClient();
      const { data: existing } = await client
        .from('UserFavoriteUniversity')
        .select('*')
        .eq('userId', userId)
        .eq('universityName', universityName)
        .maybeSingle();

      if (existing) {
        await client
          .from('UserFavoriteUniversity')
          .delete()
          .eq('id', existing.id);
        return { saved: false };
      } else {
        const { data: inserted } = await client
          .from('UserFavoriteUniversity')
          .insert({
            userId,
            universityName,
            universityData: universityData || { name: universityName },
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
          })
          .select()
          .maybeSingle();
        return { saved: true, data: inserted };
      }
    } catch (error) {
      this.logger.error(`Failed to toggle favorite university for user ${userId}:`, error);
      return { saved: false };
    }
  }

  async getFavoriteUniversities(userId: string) {
    try {
      const { data, error } = await this.supabase.getClient()
        .from('UserFavoriteUniversity')
        .select('*')
        .eq('userId', userId);

      if (error || !data) return [];
      return data;
    } catch (error) {
      this.logger.error(`Failed to get favorite universities for user ${userId}:`, error);
      return [];
    }
  }
}
