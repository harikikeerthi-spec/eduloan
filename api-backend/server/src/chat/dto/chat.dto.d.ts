export declare class CreateChatRoomDto {
    name: string;
    type: 'direct' | 'group';
    memberIds?: string[];
    description?: string;
}
export declare class CreateChatMessageDto {
    roomId: number;
    content: string;
    messageType: 'text' | 'file' | 'image' | 'system';
    fileUrl?: string;
    fileName?: string;
    fileSize?: number;
    fileMimeType?: string;
}
export declare class UpdateChatMessageDto {
    content?: string;
    status?: 'pending' | 'sent' | 'read';
}
export declare class ChatMessageResponseDto {
    id: number;
    roomId: number;
    senderId: string;
    senderName?: string;
    content: string;
    messageType: string;
    fileUrl?: string;
    fileName?: string;
    isEdited: boolean;
    status: string;
    createdAt: Date;
    readBy?: Array<{
        userId: string;
        readAt: Date;
    }>;
}
export declare class ChatRoomResponseDto {
    id: number;
    name: string;
    type: 'direct' | 'group';
    memberCount: number;
    lastMessage?: string;
    lastMessageTime?: Date;
    unreadCount?: number;
    members?: Array<{
        userId: string;
        userName: string;
        joinedAt: Date;
    }>;
    createdAt: Date;
}
export declare class UserOnlineStatusDto {
    userId: string;
    isOnline: boolean;
    lastSeen: Date;
    currentRoom?: number;
}
export declare class PaginatedMessagesDto {
    messages: ChatMessageResponseDto[];
    total: number;
    limit: number;
    offset: number;
    hasMore: boolean;
}
