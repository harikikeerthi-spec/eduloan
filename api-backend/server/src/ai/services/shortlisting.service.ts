import { Injectable, Logger } from '@nestjs/common';
import { OpenRouterService } from './open-router.service';

@Injectable()
export class ShortlistingService {
  private readonly logger = new Logger(ShortlistingService.name);

  constructor(private readonly openRouterService: OpenRouterService) {}

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
      const systemPrompt = `Return a list of 10 real universities matching the query '${query}' for ${degree} degree in ${country || 'any country'}.
      Return ONLY a JSON array of objects: [{"name": "University Name", "country": "Country", "location": "City, State", "logoUrl": ""}]`;
      
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
      const systemPrompt = `You are an expert Study Abroad Consultant. 
      Shortlist 5-6 universities for the student based on their profile.
      Return the response in strict JSON format:
      {
        "recommendations": [
          {
            "name": "University Name",
            "chance": "High | Medium | Low",
            "type": "Ambitious | Target | Safe",
            "rank": "QS World Rank",
            "tuition": "Approx Annual Tuition in USD",
            "location": "City, State",
            "country": "Country",
            "avgSalary": "Approx Avg Salary",
            "deadline": "Upcoming Deadline",
            "reason": "Why this matches the student",
            "programName": "Matching Program",
            "logoUrl": "",
            "description": "Short bio",
            "acceptanceRate": "Percentage",
            "duration": "Course length",
            "roi": "High/Medium",
            "theRank": "Times Higher Ed Rank",
            "costOfLiving": "Annual in USD",
            "websiteUrl": "official website domain"
          }
        ]
      }`;

      const userPrompt = `Profile: ${JSON.stringify(profile)}
      Conversation History: ${JSON.stringify(messages)}`;

      const response = await this.openRouterService.generateResponse(systemPrompt, userPrompt);
      const jsonMatch = response.match(/\{[\s\S]*\}/);
      return JSON.parse(jsonMatch ? jsonMatch[0] : response);
    } catch (error) {
      this.logger.error('Shortlisting failed', error);
      throw error;
    }
  }
}
