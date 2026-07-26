import { SupabaseService } from '../supabase/supabase.service';
import { CommunityService } from '../community/community.service';
import { ReferenceService } from '../reference/reference.service';
export declare class ExploreService {
    private supabase;
    private communityService;
    private referenceService;
    private get db();
    constructor(supabase: SupabaseService, communityService: CommunityService, referenceService: ReferenceService);
    private readonly hubConfigs;
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
    getAllHubs(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getHubPosts(topic: string, sort?: string, userId?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    createHubPost(userId: string, topic: string, data: any): Promise<{
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
