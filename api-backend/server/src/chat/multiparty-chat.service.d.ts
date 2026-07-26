import { SupabaseService } from '../supabase/supabase.service';
import { EmailService } from './email.service';
export declare class MultiPartyChatService {
    private readonly supabase;
    private readonly emailService;
    private readonly logger;
    constructor(supabase: SupabaseService, emailService: EmailService);
    private get db();
    getOrCreateMultiPartyConversation(data: {
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
    }): Promise<any>;
    saveMultiPartyMessage(data: {
        conversationId: string;
        senderEmail: string;
        senderName: string;
        senderRole: string;
        content: string;
        messageType?: string;
        recipientEmails?: string[];
    }): Promise<any>;
    shareDocument(data: {
        conversationId: string;
        applicationId: string;
        documentId: string;
        documentName: string;
        documentType: string;
        uploadedByEmail: string;
        uploaderRole: string;
    }): Promise<any>;
    addParticipant(data: {
        conversationId: string;
        email: string;
        fullName: string;
        role: string;
    }): Promise<any>;
    getConversationMessages(conversationId: string, userEmail?: string): Promise<any[]>;
    getConversationDocuments(conversationId: string): Promise<any[]>;
    getUserConversations(userEmail: string): Promise<{
        id: any;
        applicationId: any;
        conversationTopic: any;
        isMultiParty: any;
        status: any;
        updatedAt: any;
        metadata: any;
    }[][]>;
    getConversationParticipants(conversationId: string): Promise<any[]>;
    notifyParticipantOfMessage(data: {
        recipientEmail: string;
        senderName: string;
        senderRole: string;
        messageContent: string;
        conversationTopic: string;
        applicationNumber?: string;
        bank?: string;
    }): Promise<boolean>;
}
