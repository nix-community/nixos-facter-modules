lib:
let

  inherit (lib) assertMsg;

  hasCpu =
    name:
    {
      hardware ? { },
      ...
    }:
    let
      cpus = hardware.cpu or [ ];
    in
    assert assertMsg (hardware != { }) "no hardware entries found in the report";
    assert assertMsg (cpus != [ ]) "no cpu entries found in the report";
    builtins.any (
      {
        vendor_name ? null,
        ...
      }:
      assert assertMsg (vendor_name != null) "detail.vendor_name not found in cpu entry";
      vendor_name == name
    ) cpus;

  collectDrivers = list: lib.foldl' (lst: value: lst ++ value.driver_modules or [ ]) [ ] list;
  stringSet = list: builtins.attrNames (builtins.groupBy lib.id list);

  toZeroPaddedHex =
    n:
    let
      hex = lib.toHexString n;
      len = builtins.stringLength hex;
    in
    if len == 1 then
      "000${hex}"
    else if len == 2 then
      "00${hex}"
    else if len == 3 then
      "0${hex}"
    else
      hex;
in
{
  inherit
    hasCpu
    collectDrivers
    stringSet
    toZeroPaddedHex
    ;

  hasAmdCpu = hasCpu "AuthenticAMD";
  hasIntelCpu = hasCpu "GenuineIntel";

}
