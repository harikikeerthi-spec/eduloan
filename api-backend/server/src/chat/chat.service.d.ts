import { SupabaseService } from '../supabase/supabase.service';
export declare class ChatService {
    private readonly supabase;
    private readonly logger;
    constructor(supabase: SupabaseService);
    private get db();
    private normalizePhone;
    getOrCreateConversation(customerPhone: string, customerEmail?: string, conversationType?: string, customerName?: string, bankName?: string, additionalMetadata?: any): Promise<any>;
    saveMessage(data: {
        conversationId: string;
        senderType: string;
        senderId: string;
        receiverType?: string;
        content: string;
        messageType?: string;
        status?: string;
        attachmentUrl?: string;
        attachmentType?: string;
        senderName?: string;
    }): Promise<any>;
    getConversations(status?: string, user?: any): Promise<any[]>;
    getMessages(conversationId: string): Promise<any[]>;
    getMessageById(messageId: string): Promise<any>;
    getMessagesByPhone(phone: string): Promise<any[]>;
}
