import { CommunityService } from './community.service';
import { JwtService } from '@nestjs/jwt';
export declare class CommunityController {
    private communityService;
    private jwtService;
    constructor(communityService: CommunityService, jwtService: JwtService);
    getAllMentors(university?: string, country?: string, loanType?: string, category?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getFeaturedMentors(limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getMentorById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    bookMentorSession(mentorId: string, body: {
        studentName: string;
        studentEmail: string;
        studentPhone?: string;
        preferredDate: string;
        preferredTime: string;
        message?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    applyAsMentor(body: {
        name: string;
        email: string;
        phone?: string;
        university: string;
        degree: string;
        country: string;
        loanBank: string;
        loanAmount: string;
        bio: string;
        expertise: string[];
        linkedIn?: string;
    }): Promise<{
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
    getStats(): Promise<{
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
    getAllEvents(type?: string, category?: string, featured?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getUpcomingEvents(limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPastEvents(limit?: string, offset?: string): Promise<{
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
    registerForEvent(eventId: string, body: {
        name: string;
        email: string;
        phone?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllStories(country?: string, category?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getFeaturedStories(limit?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getStoryById(id: string): Promise<{
        success: boolean;
        data: any;
    }>;
    submitStory(body: {
        name: string;
        email: string;
        university: string;
        country: string;
        degree: string;
        loanAmount: string;
        bank: string;
        interestRate?: string;
        story: string;
        tips?: string;
        image?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllResources(type?: string, category?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getPopularResources(limit?: string): Promise<{
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
    createMentor(body: {
        name: string;
        email: string;
        university: string;
        degree: string;
        country: string;
        loanBank: string;
        loanAmount: string;
        interestRate?: string;
        bio: string;
        expertise: string[];
        rating?: number;
        studentsMentored?: number;
        image?: string;
        isActive?: boolean;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateMentor(id: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteMentor(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    createEvent(body: {
        title: string;
        description: string;
        type: string;
        category?: string;
        date: string;
        time: string;
        duration: number;
        speaker?: string;
        speakerTitle?: string;
        maxAttendees?: number;
        isFree?: boolean;
        recordingUrl?: string;
        isFeatured?: boolean;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateEvent(id: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteEvent(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    createResource(body: {
        title: string;
        description: string;
        type: string;
        category: string;
        fileUrl?: string;
        downloadUrl?: string;
        thumbnailUrl?: string;
        isFeatured?: boolean;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateResource(id: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteResource(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    approveMentor(id: string, body: {
        approved: boolean;
        reason?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    createStory(body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateStory(id: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    deleteStory(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    approveStory(id: string, body: {
        approved: boolean;
        reason?: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    getAllBookings(status?: string, mentorId?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getAllRegistrations(eventId?: string, limit?: string, offset?: string): Promise<{
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
    getAllForumPostsAdmin(category?: string, limit?: string, offset?: string, sort?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    togglePinForumPost(id: string, body: {
        isPinned: boolean;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    searchForumPosts(q?: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    getForumPostById(id: string, req: any): Promise<{
        success: boolean;
        data: any;
    }>;
    getForumPosts(category?: string, tag?: string, limit?: string, offset?: string, sort?: string, req?: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getPostsAlias(topic?: string, page?: string, req?: any): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    getHubs(): Promise<{
        success: boolean;
        data: any[];
    }>;
    getPostByIdAlias(id: string, req: any): Promise<{
        success: boolean;
        data: any;
    }>;
    createPostAlias(req: any, body: any): Promise<{
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
    createForumComment(req: any, id: string, body: {
        content: string;
        parentId?: string;
    }): Promise<{
        success: boolean;
        data: any;
        message?: undefined;
    } | {
        success: boolean;
        message: string;
        data: any;
    }>;
    likeForumComment(req: any, id: string): Promise<{
        success: boolean;
        likes: any;
        liked: boolean;
    }>;
    likeForumPost(req: any, id: string): Promise<{
        success: boolean;
        likes: any;
        liked: boolean;
    }>;
    shareForumPost(id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    deleteForumPost(req: any, id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    deleteForumComment(req: any, id: string): Promise<{
        success: boolean;
        message: string;
    }>;
    checkDuplicateQuestion(body: {
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
        success: boolean;
    } | {
        isDuplicate: boolean;
        similarQuestions: never[];
        message: string;
        error: any;
        success: boolean;
    }>;
    requestMentorOTP(body: {
        email: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: {
            otp?: string | undefined;
            email: string;
            expiresIn: number;
        };
    }>;
    verifyMentorOTP(body: {
        email: string;
        otp: string;
    }): Promise<{
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
    getMentorBookings(mentorId: string, status?: string, limit?: string, offset?: string): Promise<{
        success: boolean;
        data: any[];
        pagination: {
            total: number;
            limit: any;
            offset: any;
            hasMore: boolean;
        };
    }>;
    updateBookingStatus(mentorId: string, bookingId: string, body: {
        status: string;
    }): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
    updateMentorProfile(mentorId: string, body: any): Promise<{
        success: boolean;
        message: string;
        data: any;
    }>;
}
