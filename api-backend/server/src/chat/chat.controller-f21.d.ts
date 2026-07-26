import { ChatService } from './chat.service';
import { CreateChatRoomDto, CreateChatMessageDto, UpdateChatMessageDto, ChatRoomResponseDto, ChatMessageResponseDto, PaginatedMessagesDto } from './dto/chat.dto';
export declare class ChatController {
    private readonly chatService;
    constructor(chatService: ChatService);
    createRoom(dto: CreateChatRoomDto, req: any): Promise<ChatRoomResponseDto>;
    getRooms(req: any): Promise<ChatRoomResponseDto[]>;
    getRoom(roomId: number, req: any): Promise<ChatRoomResponseDto>;
    updateRoom(roomId: number, dto: Partial<CreateChatRoomDto>, req: any): Promise<ChatRoomResponseDto>;
    deleteRoom(roomId: number, req: any): Promise<{
        success: boolean;
    }>;
    getMessages(roomId: number, limit: number | undefined, offset: number | undefined, req: any): Promise<PaginatedMessagesDto>;
    sendMessage(dto: CreateChatMessageDto, req: any): Promise<ChatMessageResponseDto>;
    editMessage(messageId: number, dto: UpdateChatMessageDto, req: any): Promise<ChatMessageResponseDto>;
    deleteMessage(messageId: number, req: any): Promise<{
        success: boolean;
    }>;
    markMessageAsRead(messageId: number, req: any): Promise<{
        success: boolean;
    }>;
    markAllAsRead(roomId: number, req: any): Promise<{
        success: boolean;
        readCount: number;
    }>;
    addMemberToRoom(roomId: number, userId: string, req: any): Promise<{
        success: boolean;
    }>;
    removeMemberFromRoom(roomId: number, userId: string, req: any): Promise<{
        success: boolean;
    }>;
    getUserStatus(userId: string): Promise<any>;
    getOnlineUsersInRoom(roomId: number): Promise<any[]>;
}
