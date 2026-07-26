import { MultiPartyChatService } from './multiparty-chat.service';
export declare class MultiPartyChatController {
    private readonly multiPartyChatService;
    private readonly logger;
    constructor(multiPartyChatService: MultiPartyChatService);
    createMultiPartyConversation(req: any, body: {
        applicationId: string;
        customers: Array<{
            email: string;
            fullName: string;
        }>;
        staffMembers?: Array<{
            email: string;
            fullName: string;
        }>;
        bankMembers?: Array<{
            email: string;
            fullName: string;
        }>;
        topic: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getMyConversations(req: any): Promise<{
        success: boolean;
        data: {
            id: any;
            applicationId: any;
            conversationTopic: any;
            isMultiParty: any;
            status: any;
            updatedAt: any;
            metadata: any;
        }[][];
    }>;
    getConversationDetails(conversationId: string): Promise<{
        success: boolean;
        data: {
            messages: any[];
            documents: any[];
            participants: any[];
        };
    }>;
    getConversationMessages(conversationId: string, req: any): Promise<{
        success: boolean;
        data: any[];
    }>;
    sendMessage(conversationId: string, req: any, body: {
        content: string;
        recipientEmails?: string[];
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    shareDocument(conversationId: string, req: any, body: {
        applicationId: string;
        documentId: string;
        documentName: string;
        documentType: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getSharedDocuments(conversationId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    addParticipant(conversationId: string, body: {
        email: string;
        fullName: string;
        role: string;
    }): Promise<{
        success: boolean;
        data: any;
        message: string;
    }>;
    getParticipants(conversationId: string): Promise<{
        success: boolean;
        data: any[];
    }>;
    notifyByEmail(conversationId: string, req: any, body: {
        recipientEmail: string;
        messageContent: string;
        conversationTopic: string;
        applicationNumber?: string;
        bank?: string;
    }): Promise<{
        success: boolean;
        message: string;
    }>;
}
