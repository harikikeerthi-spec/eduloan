import { CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
export declare class StaffGuard implements CanActivate {
    private jwtService;
    private usersService;
    constructor(jwtService: JwtService, usersService: UsersService);
    canActivate(context: ExecutionContext): Promise<boolean>;
}
