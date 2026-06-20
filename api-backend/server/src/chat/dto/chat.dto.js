"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaginatedMessagesDto = exports.UserOnlineStatusDto = exports.ChatRoomResponseDto = exports.ChatMessageResponseDto = exports.UpdateChatMessageDto = exports.CreateChatMessageDto = exports.CreateChatRoomDto = void 0;
class CreateChatRoomDto {
    name;
    type;
    memberIds;
    description;
}
exports.CreateChatRoomDto = CreateChatRoomDto;
class CreateChatMessageDto {
    roomId;
    content;
    messageType;
    fileUrl;
    fileName;
    fileSize;
    fileMimeType;
}
exports.CreateChatMessageDto = CreateChatMessageDto;
class UpdateChatMessageDto {
    content;
    status;
}
exports.UpdateChatMessageDto = UpdateChatMessageDto;
class ChatMessageResponseDto {
    id;
    roomId;
    senderId;
    senderName;
    content;
    messageType;
    fileUrl;
    fileName;
    isEdited;
    status;
    createdAt;
    readBy;
}
exports.ChatMessageResponseDto = ChatMessageResponseDto;
class ChatRoomResponseDto {
    id;
    name;
    type;
    memberCount;
    lastMessage;
    lastMessageTime;
    unreadCount;
    members;
    createdAt;
}
exports.ChatRoomResponseDto = ChatRoomResponseDto;
class UserOnlineStatusDto {
    userId;
    isOnline;
    lastSeen;
    currentRoom;
}
exports.UserOnlineStatusDto = UserOnlineStatusDto;
class PaginatedMessagesDto {
    messages;
    total;
    limit;
    offset;
    hasMore;
}
exports.PaginatedMessagesDto = PaginatedMessagesDto;
//# sourceMappingURL=chat.dto.js.map