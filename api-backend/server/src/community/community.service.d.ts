import { SupabaseService } from '../supabase/supabase.service';
import { OpenRouterService } from '../ai/services/openrouter.service';
export declare class CommunityService {
    private supabase;
    private openRouterService;
    private get db();
    private otpStore;
    constructor(supabase: SupabaseService, openRouterService: OpenRouterService);
    getAllMentors(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getFeaturedMentors(limit: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    getMentorById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    bookMentorSession(mentorId: string, bookingData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    applyAsMentor(applicationData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getMentorStats(): Promise<{
        success: boolean;
        data: {
            totalMentors: number;
            activeMentors: number;
            averageRating: number;
            totalStudentsMentored: any;
        };
    }>;
    getAllEvents(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getUpcomingEvents(limit: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPastEvents(limit: number, offset: number): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: number;
            offset: number;
            hasMore: boolean;
        };
    }>;
    getEventById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    registerForEvent(eventId: string, registrationData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllStories(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getFeaturedStories(limit: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    getStoryById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    submitStory(storyData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllResources(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getPopularResources(limit: number): Promise<{
        success: boolean;
        data: any[];
    }>;
    getResourceById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    trackResourceView(resourceId: string): Promise<{
        success: boolean;
        data: {
            downloads: any;
        };
    }>;
    createMentor(mentorData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateMentor(id: string, updateData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteMentor(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    createEvent(eventData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateEvent(id: string, updateData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteEvent(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    createResource(resourceData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateResource(id: string, updateData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteResource(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    createStory(storyData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateStory(id: string, updateData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteStory(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    approveMentor(id: string, approved: boolean, reason?: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    approveStory(id: string, approved: boolean, reason?: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllBookings(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getAllRegistrations(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getCommunityStats(): Promise<{
        success: boolean;
        data: {
            mentors: number;
            events: number;
            stories: number;
            resources: number;
            bookings: number;
            registrations: number;
            forumPosts: number;
        };
    }>;
    getForumPosts(filters: any, userId?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getForumPostById(id: string, userId?: string): Promise<{
        success: boolean;
        data: any;
    }>;
    searchSimilarPosts(query: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getHubs(): Promise<{
        success: boolean;
        data: any[];
    }>;
    private checkContentRelevance;
    createForumPost(userId: string, data: any): Promise<{
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
    createForumComment(userId: string, postId: string, content: string, parentId?: string): Promise<{
        success: boolean;
        data: any;
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        data: any;
    }>;
    likeForumComment(userId: string, id: string): Promise<{
        success: boolean;
        likes: any;
        liked: boolean;
    }>;
    likeForumPost(userId: string, id: string): Promise<{
        success: boolean;
        likes: any;
        liked: boolean;
    }>;
    shareForumPost(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    deleteForumPost(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    deleteForumComment(userId: string, userRole: string, commentId: string): Promise<{
        success: boolean;
        message: string;
    }>;
    requestMentorOTP(email: string): Promise<{
        success: boolean;
        message: string;
        data: {
            otp?: string | undefined;
            email: string;
            expiresIn: number;
        };
    }>;
    verifyMentorOTP(email: string, otp: string): Promise<{
        success: boolean;
        message: string;
        data: {
            id: any;
            name: any;
            email: any;
            university: any;
            isApproved: any;
            isActive: any;
        };
    }>;
    getMentorProfile(mentorId: string): Promise<{
        success: boolean;
        data: {
            mentor: any;
            stats: {
                total: number;
                pending: number;
                approved: number;
                rejected: number;
                completed: number;
            };
        };
    }>;
    getMentorBookings(mentorId: string, filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    updateBookingStatus(mentorId: string, bookingId: string, status: string): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateMentorProfile(mentorId: string, updateData: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllForumPostsAdmin(filters: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    togglePinForumPost(id: string, isPinned: boolean): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    checkDuplicateQuestion(questionData: {
        title: string;
        content: string;
        category: string;
    }): Promise<{
        isDuplicate: boolean;
        similarQuestions: {
            id: any;
            title: any;
            similarity: number;
            reason: string;
            url: string;
        }[];
        message: string;
        error?: undefined;
    } | {
        isDuplicate: boolean;
        similarQuestions: never[];
        message: string;
        error: any;
    }>;
}
