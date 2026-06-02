import { Injectable, Logger } from '@nestjs/common';
import { OpenRouterService } from './open-router.service';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ShortlistingService {
  private readonly logger = new Logger(ShortlistingService.name);

  constructor(
    private readonly openRouterService: OpenRouterService,
    private readonly prisma: PrismaService,
  ) {}

  private readonly popularCountries = [
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

  async searchCountries(query: string): Promise<any[]> {
    if (!query) return this.popularCountries;
    return this.popularCountries.filter((c) =>
      c.name.toLowerCase().includes(query.toLowerCase()),
    );
  }

  async searchFields(query: string): Promise<string[]> {
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

  async searchUniversities(query: string, degree: string, country?: string): Promise<any[]> {
    try {
      const systemPrompt = `List 10 real universities/colleges matching '${query}' for ${degree} in ${country || 'any'}.
      Include exact matches for specific names (e.g. 'Vishnu College').
      For Indian results, include town (e.g. Bhimavaram).
      JSON array: [{"name": "Name", "country": "Country", "location": "City, State"}]`;
      
      const response = await this.openRouterService.generateResponse(systemPrompt, `Search: ${query}`);
      const jsonMatch = response.match(/\[[\s\S]*\]/);
      return JSON.parse(jsonMatch ? jsonMatch[0] : response);
    } catch (error) {
      this.logger.error('University search failed', error);
      return [];
    }
  }

  async searchCourses(university: string, query: string, degree: string): Promise<any[]> {
    try {
      const systemPrompt = `Return a list of 10 real courses/programs matching '${query}' at ${university} for ${degree} degree.
      Return ONLY a JSON array of strings or objects: ["Program Name"]`;
      
      const response = await this.openRouterService.generateResponse(systemPrompt, `Search: ${query}`);
      const jsonMatch = response.match(/\[[\s\S]*\]/);
      return JSON.parse(jsonMatch ? jsonMatch[0] : response);
    } catch (error) {
      this.logger.error('Course search failed', error);
      return [];
    }
  }

  async shortlist(profile: any, messages: any[] = []): Promise<any> {
    try {
      const systemPrompt = `You are a Study Abroad Consultant. Shortlist 5-6 universities.
      CRITICAL: Keep "reason" and "description" fields concise (1-2 sentences maximum) to avoid token truncation.
      JSON format:
      {
        "recommendations": [
          {
            "name": "Name", "chance": "High/Med/Low", "type": "Safe/Target/Ambitious", "rank": "Rank", "tuition": "USD", "location": "City, State",
            "country": "Country", "avgSalary": "Salary", "deadline": "Date", "reason": "Why", "programName": "Program", "logoUrl": "",
            "description": "Bio", "acceptanceRate": "%", "duration": "Years", "roi": "H/M/L", "theRank": "THE Rank", "costOfLiving": "USD", "websiteUrl": "url"
          }
        ]
      }`;

      const userPrompt = `Profile: ${JSON.stringify(profile)}
      Conversation History: ${JSON.stringify(messages)}`;

      const response = await this.openRouterService.generateResponse(
        systemPrompt,
        userPrompt,
        0.7,
        4096,
      );
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      const jsonStr = jsonMatch ? jsonMatch[0] : response;
      try {
        return JSON.parse(jsonStr);
      } catch (parseError) {
        this.logger.error('Failed to parse JSON. Raw JSON string tried to parse:', jsonStr);
        throw parseError;
      }
    } catch (error) {
      this.logger.error('Shortlisting failed', error);
      throw error;
    }
  }

  async saveShortlistChat(userId: string, messages: any[], recommendations: any[]): Promise<any> {
    try {
      return await this.prisma.universityShortlistChat.upsert({
        where: { userId },
        update: {
          messages: messages || [],
          recommendations: recommendations || [],
          updatedAt: new Date(),
        },
        create: {
          userId,
          messages: messages || [],
          recommendations: recommendations || [],
        },
      });
    } catch (error) {
      this.logger.error(`Failed to save shortlist chat for user ${userId}`, error);
      throw error;
    }
  }

  async getLatestShortlistChat(userId: string): Promise<any> {
    try {
      return await this.prisma.universityShortlistChat.findUnique({
        where: { userId },
      });
    } catch (error) {
      this.logger.error(`Failed to get shortlist chat for user ${userId}`, error);
      throw error;
    }
  }
}
