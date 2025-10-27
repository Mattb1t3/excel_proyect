import { Component, OnInit } from '@angular/core';
import { NotificationService, Notification } from '../../services/notification.service';

@Component({
  selector: 'app-notification',
  template: `
    <div class="notification-container">
      <div 
        *ngFor="let notification of notifications" 
        class="notification"
        [class.success]="notification.type === 'success'"
        [class.error]="notification.type === 'error'"
        [class.warning]="notification.type === 'warning'"
        [class.info]="notification.type === 'info'"
        [@slideIn]>
        <div class="notification-icon">
          <span *ngIf="notification.type === 'success'">✓</span>
          <span *ngIf="notification.type === 'error'">✗</span>
          <span *ngIf="notification.type === 'warning'">⚠</span>
          <span *ngIf="notification.type === 'info'">ℹ</span>
        </div>
        <div class="notification-content">
          <h4>{{ notification.title }}</h4>
          <p>{{ notification.message }}</p>
        </div>
        <button class="notification-close" (click)="removeNotification(notification)">×</button>
      </div>
    </div>
  `,
  styles: [`
    .notification-container {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 9999;
      display: flex;
      flex-direction: column;
      gap: 1rem;
      max-width: 400px;
    }

    .notification {
      display: flex;
      align-items: flex-start;
      gap: 1rem;
      padding: 1rem;
      background: white;
      border-radius: 8px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      border-left: 4px solid;
      animation: slideIn 0.3s ease-out;

      &.success {
        border-left-color: #27ae60;
        .notification-icon { background: #d5f4e6; color: #27ae60; }
      }

      &.error {
        border-left-color: #e74c3c;
        .notification-icon { background: #fadbd8; color: #e74c3c; }
      }

      &.warning {
        border-left-color: #f39c12;
        .notification-icon { background: #fff3cd; color: #f39c12; }
      }

      &.info {
        border-left-color: #3498db;
        .notification-icon { background: #d6eaf8; color: #3498db; }
      }

      .notification-icon {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        font-size: 1.2rem;
        flex-shrink: 0;
      }

      .notification-content {
        flex: 1;

        h4 {
          margin: 0 0 0.3rem 0;
          font-size: 1rem;
          color: #2c3e50;
        }

        p {
          margin: 0;
          font-size: 0.9rem;
          color: #7f8c8d;
        }
      }

      .notification-close {
        background: none;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        color: #95a5a6;
        padding: 0;
        width: 24px;
        height: 24px;
        flex-shrink: 0;

        &:hover {
          color: #2c3e50;
        }
      }
    }

    @keyframes slideIn {
      from {
        transform: translateX(400px);
        opacity: 0;
      }
      to {
        transform: translateX(0);
        opacity: 1;
      }
    }
  `]
})
export class NotificationComponent implements OnInit {
  notifications: Notification[] = [];

  constructor(private notificationService: NotificationService) {}

  ngOnInit(): void {
    this.notificationService.getNotifications().subscribe(notification => {
      this.notifications.push(notification);

      // Auto-remover después de la duración especificada
      setTimeout(() => {
        this.removeNotification(notification);
      }, notification.duration || 5000);
    });
  }

  removeNotification(notification: Notification): void {
    const index = this.notifications.indexOf(notification);
    if (index > -1) {
      this.notifications.splice(index, 1);
    }
  }
}