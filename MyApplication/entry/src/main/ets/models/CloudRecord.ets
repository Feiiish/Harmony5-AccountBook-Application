import { cloudDatabase } from '@kit.CloudFoundationKit';

class CloudRecord extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "CloudRecord";
  }

  public id: string | undefined;
  public amount: number | undefined;
  public unit: string | undefined;
  public tag: string | undefined;
  public note: string | undefined;
  public date: string | undefined;
  public selectimageUriedImage: ResourceStr | undefined;
  public fromAccount: string | undefined;
  public fromBookID: string | undefined;
}

export { CloudRecord };