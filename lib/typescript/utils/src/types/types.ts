import { EInvalidateCacheFields } from './enums';

export interface IAWSInvalidateRequest {
  [EInvalidateCacheFields.AWS_ACCOUNT]          : string,
  [EInvalidateCacheFields.DISTRIBUTION_ID]      : string,
  [EInvalidateCacheFields.INVALIDATION_PATH]    : string[],
  [EInvalidateCacheFields.SLACK_WEBHOOK]        ?: string,
  [EInvalidateCacheFields.SLACK_CHANNEL]        ?: string,
  [EInvalidateCacheFields.SLACK_USERNAME]       ?: string,
  [EInvalidateCacheFields.SLACK_GITHUB_BRANCH]  ?: string,
  [EInvalidateCacheFields.SLACK_SITE_URL]       ?: string,
}