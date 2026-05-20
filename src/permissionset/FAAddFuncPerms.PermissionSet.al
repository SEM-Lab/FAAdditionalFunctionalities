namespace Infotek.FAAdditionalFunctionalities;

permissionset 60000 "FA Add Func Perms"
{
    Caption = 'FA Add. Functions', Locked = true;
    Assignable = true;
    Access = Public;
    Permissions = tabledata "FA Conversion" = RIMD,
        tabledata "FA Conversion Setup" = RIMD,
        table "FA Conversion" = X,
        table "FA Conversion Setup" = X,
        codeunit "FA Conversion Functions" = X,
        page "FA Conversion" = X,
        page "FA Conversion Setup" = X,
        page "FA Conversion Wizard" = X,
        page "FA Conversion List" = X,
        codeunit "FA Transfer Functions" = X,
        page "Posted Direct Transfer Lines" = X,
        codeunit "FA Location Sync Handler" = X,
        page "Pstd Transfer RcptLns INF" = X,
        tabledata "FA Depreciation Profile" = RIMD,
        table "FA Depreciation Profile" = X,
        codeunit "Location Type Automation" = X,
        page "FA Depreciation Profiles" = X;
}