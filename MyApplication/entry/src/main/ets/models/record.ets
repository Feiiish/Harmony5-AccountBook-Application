import { cloudDatabase } from '@kit.CloudFoundationKit';

class record extends cloudDatabase.DatabaseObject {
  public naturalbase_ClassName(): string {
    return "record";
  }

  public id: string | undefined;
  public amount: number | undefined;
  public unit: string | undefined;
  public tag: string | undefined;
  public note: string | undefined;
  public date: string | undefined;
  public selectimageUriedImage: ResourceStr | undefined;
}

export { record };