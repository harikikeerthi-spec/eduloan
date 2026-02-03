import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { JwtModule } from '@nestjs/jwt';
import { EmailService } from './email.service';

@Module({
    imports: [
        UsersModule,
        JwtModule.register({
            global: true,
            secret: 'secretKey', // In production, use process.env.JWT_SECRET
            signOptions: { expiresIn: '60d' }, // Long expiry for dev convenience
        }),
    ],
    providers: [AuthService, EmailService],
    controllers: [AuthController],
    exports: [AuthService],
})
export class AuthModule { }
