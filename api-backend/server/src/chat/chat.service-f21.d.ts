import { SupabaseService } from '../supabase/supabase.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
export declare class ChatServiceF21 {
    private readonly supabase;
    private readonly eventEmitter;
    constructor(supabase: SupabaseService, eventEmitter: EventEmitter2);
    private get db();
    createRoom(userId: string, roomData: any): Promise<any>;
    getUserRooms(userId: string): Promise<any[]>;
    getRoomDetails(roomId: number, userId?: string): Promise<any>;
    updateRoom(roomId: number, updates: any, userId: string): Promise<any>;
    deleteRoom(roomId: number, userId: string): Promise<boolean>;
    sendMessage(roomId: number, userId: string, messageData: any): Promise<any>;
    getMessages(roomId: number, userId: string, limit?: number, offset?: number): Promise<any>;
    editMessage(messageId: number, userId: string, newContent: string): Promise<any>;
    deleteMessage(messageId: number, userId: string): Promise<boolean>;
    addMemberToRoom(roomId: number, newUserId: string, addedBy: string): Promise<boolean>;
    removeMemberFromRoom(roomId: number, userId: string, removedBy: string): Promise<boolean>;
    getRoomMembers(roomId: number): Promise<any[]>;
    isUserMemberOfRoom(roomId: number, userId: string): Promise<boolean>;
    markMessageAsRead(messageId: number, userId: string): Promise<boolean>;
    markAllMessagesAsRead(roomId: number, userId: string): Promise<number>;
    getMessageReadReceipts(messageId: number): Promise<any[]>;
    updateUserOnlineStatus(userId: string, isOnline: boolean, currentRoom?: number): Promise<void>;
    getUserOnlineStatus(userId: string): Promise<any>;
    getOnlineUsersInRoom(roomId: number): Promise<any[]>;
    uploadChatFile(roomId: number, userId: string, file: Express.Multer.File): Promise<{
        fileUrl: string;
        fileName: string;
        fileSize: number;
    }>;
    setUserTypingStatus(roomId: number, userId: string, isTyping: boolean): Promise<void>;
    getUnreadCount(userId: string): Promise<{
        [roomId: number]: number;
    }>;
    cleanupOldMessages(daysToKeep?: number): Promise<number>;
}
