import { MessageAttachment } from '@slack/types';
import { IncomingWebhook } from '@slack/webhook';
import { IAWSInvalidateRequest } from '../types';

const SLACK_ICON = 'https://avatars.githubusercontent.com/u/7389719?s=24&v=4';

export class SlackNotificationService {
  private title:          string;
  private webhook:        string | null = null;
  private channel:        string | null = null;
  private username:       string | null = null;
  private github_branch:  string | null = null;
  private site_url:       string | null = null;

  constructor(title: string) {
    this.title = title;

    this.webhook        = process.env.SLACK_NOTIFICATION_WEBHOOK ?? null;
    this.channel        = process.env.SLACK_NOTIFICATION_CHANNEL ?? null;
    this.username       = process.env.SLACK_NOTIFICATION_USERNAME ?? null;
    this.github_branch  = process.env.SLACK_NOTIFICATION_GITHUB_BRANCH ?? null;
    this.site_url       = process.env.SLACK_NOTIFICATION_SITE_URL ?? null;
  }

  private getClient(): IncomingWebhook | null {
    const defaults = this.channel ? { channel: this.channel } : undefined;

    return this.webhook ? new IncomingWebhook(this.webhook, defaults) : null;
  }

  public setWebhook(webhook: string | undefined): this {
    if (webhook) {
      this.webhook = webhook;
    }

    return this;
  }

  public setChannel(channel: string | undefined): this {
    if (channel) {
      this.channel = channel;
    }

    return this;
  }

  public setUsername(username: string | undefined): this {
    if (username) {
      this.username = username;
    }

    return this;
  }

  public setBranch(github_branch: string | undefined): this {
    if (github_branch) {
      this.github_branch = github_branch;
    }

    return this;
  }

  public setSiteUrl(site_url: string | undefined): this {
    if (site_url) {
      this.site_url = site_url;
    }

    return this;
  }

  public async send(text: string, color = '#fff', title?: string) {
    const client = this.getClient();

    if (client) {
      console.warn('Slack notification service not initialized');
    }

    const message: MessageAttachment = {
      text,
      color: color,
      author_icon: SLACK_ICON,
      title: title ?? this.title,
    };

    await client?.send({
      attachments: [message]
    });
  }

  public async success(text: string, title?: string) {
    return await this.send(`:white_check_mark: ${text}`, 'good', title);
  }

  public async error(text: string, title?: string) {
    return await this.send(`:x: ${text}`, 'danger', title);
  }

  public async warn(text: string, title?: string) {
    return await this.send(`${text}`, 'warning', title);
  }

  public getMessageForRequest(text: string, request: IAWSInvalidateRequest | null): string {
    if (!request) {
      return text;
    }

    let message = `${text}\n\nDistribution: ${request.distribution_id} (${request.aws_account})`;
    message = `${message}\nPaths: ${request.invalidation_path.join(', ')}`;
    message = this.github_branch ? `${message}\nBranch: ${this.github_branch}` : message;
    message = this.username ? `${message}\nUsername: ${this.username}` : message;
    message = this.site_url ? `${message}\nSite URL: ${this.site_url}` : message;

    return message;
  }
}