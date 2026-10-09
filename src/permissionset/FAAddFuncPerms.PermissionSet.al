namespace Infotek.FAAdditionalFunctionalities;

/// <summary>
/// Full access to the objects of the Fixed Asset Additional Functionalities extension.
/// </summary>
permissionset 60000 "FA Add Func Perms"
{
    Caption = 'FA Add. Functions', Locked = true;
    Assignable = true;
    Access = Public;
    Permissions = table "FA Conv. Source Line INF" = X,
        tabledata "FA Conv. Source Line INF" = RIMD,
        table "FA Conversion" = X,
        tabledata "FA Conversion" = RIMD,
        table "FA Conversion Setup" = X,
        tabledata "FA Conversion Setup" = RIMD,
        table "FA Depreciation Profile" = X,
        tabledata "FA Depreciation Profile" = RIMD,
        codeunit "FA Add Func Upgrade" = X,
        codeunit "FA Conversion Functions" = X,
        codeunit "FA Conversion Request Mgt. INF" = X,
        codeunit "FA Location Sync Handler" = X,
        codeunit "FA Page Functions" = X,
        codeunit "FA Transfer Functions" = X,
        codeunit "Location Type Automation" = X,
        page "FA Conversion" = X,
        page "FA Conversion List" = X,
        page "FA Conversion Request INF" = X,
        page "FA Conversion Setup" = X,
        page "FA Conversion Wizard" = X,
        page "FA Depreciation Profiles" = X,
        page "Posted Direct Transfer Lines" = X,
        page "Pstd Transfer RcptLns INF" = X;
}