import { ExploreService } from './explore.service';
import { JwtService } from '@nestjs/jwt';
export declare class ExploreController {
    private exploreService;
    private jwtService;
    constructor(exploreService: ExploreService, jwtService: JwtService);
    getAllHubs(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getHubData(topic: string): Promise<{
        success: boolean;
        data: {
            hub: {
                topic: string;
                originalTopic: string;
                title: any;
                badge: any;
                description: any;
                advice: any;
                icon: any;
                stats: {
                    activeMentors: number;
                    discussions: number;
                    members: number;
                };
            };
            featuredMentorPost: any;
            mentors: any[];
            events: any[];
            resources: any[];
            stories: any[];
            forumPosts: any[];
        };
    }>;
    getHubPosts(topic: string, req: any, sort?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    createHubPost(req: any, topic: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
        isDuplicate: boolean;
    } | {
        success: boolean;
        message: string;
        data: any;
        isDuplicate?: undefined;
    }>;
}
