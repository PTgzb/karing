// ignore_for_file: unused_catch_stack, empty_catches

import 'dart:async';
import 'dart:io';

import 'package:country/country.dart' as country;
import 'package:file_picker/file_picker.dart';
import 'package:karing/app/utils/analytics_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:karing/app/local_services/vpn_service.dart';
import 'package:karing/app/modules/remote_config_manager.dart';
import 'package:karing/app/modules/server_manager.dart';
import 'package:karing/app/modules/setting_manager.dart';
import 'package:karing/app/runtime/return_result.dart';
import 'package:karing/app/utils/app_scheme_utils.dart';
import 'package:karing/app/utils/auto_conf_utils.dart';
import 'package:karing/app/utils/backup_and_sync_utils.dart';
import 'package:karing/app/utils/did.dart';
import 'package:karing/app/utils/file_utils.dart';
import 'package:karing/app/utils/http_utils.dart';
import 'package:karing/app/utils/network_utils.dart';
import 'package:karing/app/utils/path_utils.dart';
import 'package:karing/app/utils/platform_utils.dart';
import 'package:karing/i18n/strings.g.dart';
import 'package:karing/screens/add_profile_by_import_from_file_screen.dart';
import 'package:karing/screens/add_profile_by_link_or_content_screen.dart';
import 'package:karing/screens/add_profile_by_scan_qrcode_screen.dart';
import 'package:karing/screens/backup_and_sync_icloud_screen.dart';
import 'package:karing/screens/backup_and_sync_lan_sync.dart';
import 'package:karing/screens/backup_and_sync_webdav_screen.dart';
import 'package:karing/screens/dialog_utils.dart';
import 'package:karing/screens/diversion_rule_detect_screen.dart';
import 'package:karing/screens/diversion_rules_screen.dart';
import 'package:karing/screens/dns_auto_setup_screen.dart';
import 'package:karing/screens/dns_settings_screen.dart';
import 'package:karing/screens/group_item.dart';
import 'package:karing/screens/group_options_helper.dart';
import 'package:karing/screens/group_screen.dart';
import 'package:karing/screens/home_tvos_screen.dart';
import 'package:karing/screens/map_list_add_screen.dart';
import 'package:karing/screens/qrcode_scan_screen.dart';
import 'package:karing/screens/region_settings_screen.dart';
import 'package:karing/screens/urltest_group_custom_screen.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:tuple/tuple.dart';
import 'package:karing/app/utils/tag_gen.dart';

class GroupHelper {
  static Future<String> showUserAgent(
      BuildContext context, String compatible) async {
    final tcontext = Translations.of(context);
    List<String> userAgents = HttpUtils.getUserAgents();
    List<String> userAgent = compatible.split(";");
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      GroupItem options = GroupItem(options: []);
      for (var ua in userAgents) {
        options.options.add(GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: ua.trim(),
                switchValue: userAgent.contains(ua),
                onSwitch: (bool value) async {
                  if (value) {
                    if (!userAgent.contains(ua)) {
                      userAgent.add(ua);
                    }
                  } else {
                    if (userAgent.length == 1) {
                      return;
                    }
                    userAgent.remove(ua);
                  }
                })));
      }

      return [options];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("UserAgent"),
            builder: (context) => GroupScreen(
                  title: tcontext.userAgent,
                  getOptions: getOptions,
                )));
    List<String> userAgentSorted = [];
    for (var ua in userAgents) {
      if (userAgent.contains(ua)) {
        userAgent.remove(ua);
        userAgentSorted.add(ua);
      }
    }
    userAgentSorted.addAll(userAgent);
    return userAgentSorted.join(";");
  }

  static Future<void> showAddProfile(BuildContext context) async {
    Map<String, int> tagSets = {};
    for (var item in ServerManager.getConfig().items) {
      tagSets[item.remark] = 0;
    }
    var tagGen = TagGen(tagSets: tagSets);
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.AddProfileByLinkOrContentScreen.title,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                              AddProfileByLinkOrContentScreen.routSettings(),
                          builder: (context) =>
                              const AddProfileByLinkOrContentScreen(
                                  name: null, linkUrl: "")));
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.importFromClipboard,
                onPush: () async {
                  ClipboardData? data;
                  try {
                    data = await Clipboard.getData("text/plain");
                  } catch (err) {
                    if (!context.mounted) {
                      return;
                    }
                    DialogUtils.showAlertDialog(context, err.toString());
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  if (data == null || data.text == null || data.text!.isEmpty) {
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                              AddProfileByLinkOrContentScreen.routSettings(),
                          builder: (context) => AddProfileByLinkOrContentScreen(
                              name: null, linkUrl: data!.text!)));
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.AddProfileByImportFromFileScreen.title,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                              AddProfileByImportFromFileScreen.routSettings(),
                          builder: (context) =>
                              const AddProfileByImportFromFileScreen(
                                  title: "",
                                  type: SubscriptionLinkType.unknown)));
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.scanQrcode,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                              AddProfileByScanQrcodeScanScreen.routSettings(),
                          builder: (context) =>
                              const AddProfileByScanQrcodeScanScreen())).then(
                      (value) {
                    if ((value != null) && (value.qrcode != null)) {
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: AddProfileByLinkOrContentScreen
                                  .routSettings(),
                              builder: (context) =>
                                  AddProfileByLinkOrContentScreen(
                                      name: null, linkUrl: value.qrcode!)));
                    }
                  });
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.custom,
                onPush: () async {
                  String? text = await DialogUtils.showTextInputDialog(
                      context, tcontext.custom, "", null, null, (text) {
                    text = text.trim();
                    if (text.isEmpty) {
                      DialogUtils.showAlertDialog(
                          context, tcontext.remarkCannotEmpty);
                      return false;
                    }
                    if (text.length > kRemarkMaxLength) {
                      DialogUtils.showAlertDialog(
                          context, tcontext.remarkTooLong);
                      return false;
                    }
                    if (ServerManager.hasGroupByRemark(text)) {
                      DialogUtils.showAlertDialog(
                          context, tcontext.remarkExist);
                      return false;
                    }
                    return true;
                  });
                  if (text == null) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }

                  ServerManager.addLocalCusteomConfig(text);
                })),
        !Platform.isIOS &&
                !Platform.isMacOS &&
                !RemoteConfigManager.getConfig().nowarp.contains(
                    SettingManager.getConfig().regionCode.toLowerCase())
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: "WARP",
                    onPush: () async {
                      DialogUtils.showLoadingDialog(context, text: "");
                      List<String> urls = [];
                      for (int i = 0; i < 5; ++i) {
                        urls.add("warp://auto?ifpd=10-20#Warp_$i");
                      }
                      var err = await ServerManager.addRemoteConfig(
                          "",
                          tagGen.gen("WARP"),
                          urls.join("\n"),
                          SubscriptionLinkType.v2ray,
                          "",
                          false,
                          null);
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pop(context);
                      if (err != null) {
                        DialogUtils.showAlertDialog(context, err.message);
                      } else {
                        DialogUtils.showAlertDialog(
                            context,
                            tcontext.addSuccessThen(
                                p: t.MyProfilesScreen.title));
                      }
                    }))
            : GroupItemOptions(),
      ];
      var backup = GroupItem(options: [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
          name: tcontext.backupAndSync,
          onPush: () async {
            GroupHelper.showBackupAndSync(context);
          },
        )),
      ]);

      return [
        GroupItem(
            options: GroupOptionsHelper.getOutlinkOptions(
                context, "showAddProfile")),
        GroupItem(options: options),
        backup
      ];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("addProfile"),
            builder: (context) => GroupScreen(
                  title: tcontext.addProfile,
                  getOptions: getOptions,
                )));
  }

  static Future<void> showDns(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();

      List<GroupItemOptions> options = [
        !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.SettingsScreen.dnsEnableRule,
                    switchValue: settingConfig.dns.enableRule,
                    tips: tcontext.SettingsScreen.dnsEnableRuleTips,
                    onSwitch: (bool value) async {
                      settingConfig.dns.enableRule = value;
                      SettingManager.setDirty(true);
                    }))
            : GroupItemOptions(),
        !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.SettingsScreen.dnsEnableClientSubnet,
                    switchValue: settingConfig.dns.enableClientSubnet,
                    onSwitch: (bool value) async {
                      settingConfig.dns.enableClientSubnet = value;
                      SettingManager.setDirty(true);
                    }))
            : GroupItemOptions(),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.SettingsScreen.dnsEnableFakeIp,
                switchValue: settingConfig.dns.enableFakeIp,
                tips: tcontext.SettingsScreen.dnsEnableFakeIpTips,
                onSwitch: (bool value) async {
                  settingConfig.dns.enableFakeIp = value;
                  SettingManager.setDirty(true);
                })),
        !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.SettingsScreen.dnsEnableProxyResolveByProxy,
                    switchValue: settingConfig.dns.enableProxyResolveByProxy,
                    onSwitch: !settingConfig.dns.enableRule ||
                            settingConfig.dns.enableFakeIp
                        ? null
                        : (bool value) async {
                            settingConfig.dns.enableProxyResolveByProxy = value;
                            SettingManager.setDirty(true);
                          }))
            : GroupItemOptions(),
        !settingConfig.novice
            ? GroupItemOptions(
                switchOptions: GroupItemSwitchOptions(
                    name: tcontext.SettingsScreen.dnsEnableFinalResolveByProxy,
                    switchValue: settingConfig.dns.enableFinalResolveByProxy,
                    onSwitch: (bool value) async {
                      settingConfig.dns.enableFinalResolveByProxy = value;
                      SettingManager.setDirty(true);
                    }))
            : GroupItemOptions(),
      ];

      List<GroupItemOptions> options0 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
          name: tcontext.staticIP,
          onPush: () async {
            onTapDNSStaticIP(context);
          },
        )),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.SettingsScreen.inboundDomainResolve,
                tips: tcontext.SettingsScreen.inboundDomainResolveTips(
                    p: settingConfig.proxy.mixedPort),
                switchValue: settingConfig.dns.enableInboundDomainResolve,
                onSwitch: (bool value) async {
                  settingConfig.dns.enableInboundDomainResolve = value;
                  SettingManager.setDirty(true);
                }))
      ];
      List<GroupItemOptions> options1 = [
        !settingConfig.novice
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.SettingsScreen.dnsTestDomain,
                    text: SettingManager.getConfig().dns.testDomain,
                    textWidthPercent: 0.5,
                    onPush: () async {
                      String? text = await DialogUtils.showTextInputDialog(
                          context,
                          tcontext.SettingsScreen.dnsTestDomain,
                          SettingManager.getConfig().dns.testDomain,
                          null,
                          null, (text) {
                        text = text.trim();
                        if (text.isEmpty) {
                          return false;
                        }

                        if (!NetworkUtils.isDomain(text, false)) {
                          DialogUtils.showAlertDialog(context,
                              tcontext.SettingsScreen.dnsTestDomainInvalid);
                          return false;
                        }
                        return true;
                      });
                      if (text == null) {
                        return;
                      }
                      SettingManager.getConfig().dns.testDomain = text;
                      SettingManager.setDirty(true);
                      SettingManager.saveConfig();
                    }))
            : GroupItemOptions(),
      ];
      List<GroupItemOptions> options2 = [
        GroupItemOptions(
            timerIntervalPickerOptions: GroupItemTimerIntervalPickerOptions(
                name: "TTL",
                duration: settingConfig.dns.ttl,
                notShowDisable: true,
                onPicker: (bool canceled, Duration? duration) async {
                  if (canceled) {
                    return;
                  }

                  if (duration == settingConfig.dns.ttl) {
                    return;
                  }

                  settingConfig.dns.ttl = duration ?? const Duration(hours: 12);
                  SettingManager.setDirty(true);
                  SettingManager.saveConfig();
                }))
      ];

      List<GroupItemOptions> options3 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.server,
                textWidthPercent: 0.5,
                onPush: () async {
                  onTapDNSServer(context);
                }))
      ];

      if (settingConfig.novice) {
        return [
          GroupItem(options: options),
          GroupItem(options: options1),
          GroupItem(options: options3),
        ];
      }
      return [
        GroupItem(options: options),
        GroupItem(options: options0),
        GroupItem(options: options1),
        GroupItem(options: options2),
        GroupItem(options: options3),
      ];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("dns"),
            builder: (context) => GroupScreen(
                  title: tcontext.dns,
                  getOptions: getOptions,
                )));
  }

  static Future<void> showDeversion(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      country.Country? currentCountry =
          RegionSettingsScreen.getCurrentCountry();
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.RegionSettingsScreen.title,
                text: currentCountry!
                    .isoShortNameByLocale[RegionSettingsScreen.languageTag()],
                onPush: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: RegionSettingsScreen.routSettings(),
                          builder: (context) => const RegionSettingsScreen(
                                canGoBack: true,
                                nextText: null,
                              )));
                })),
      ];

      List<GroupItemOptions> options1 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: "Rule Set",
                onPush: () async {
                  await onTapRuleset(context);
                })),
      ];

      List<GroupItemOptions> options2 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.urlTestCustomGroup,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: UrlTestGroupCustomScreen.routSettings(),
                          builder: (context) =>
                              const UrlTestGroupCustomScreen()));
                })),
      ];
      List<GroupItemOptions> options3 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.diversionRules,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DiversionRulesScreen.routSettings(),
                          builder: (context) => const DiversionRulesScreen()));
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.DiversionRuleDetectScreen.title,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DiversionRuleDetectScreen.routSettings(),
                          builder: (context) =>
                              const DiversionRuleDetectScreen()));
                })),
      ];

      return [
        GroupItem(options: options),
        GroupItem(options: options1),
        GroupItem(options: options2),
        GroupItem(options: options3),
      ];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("diversion"),
            builder: (context) => GroupScreen(
                  title: tcontext.diversion,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapRuleset(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.rulesetGeoSite,
                onPush: () async {
                  await onTapGeoSite(context);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.rulesetGeoIp,
                onPush: () async {
                  await onTapGeoIP(context);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.rulesetAcl,
                onPush: () async {
                  await onTapAcl(context);
                })),
      ];
      List<GroupItemOptions> options1 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.rulesetDirectDownlad,
                onPush: () async {
                  await onTapRuleSetDirectDownload(context);
                })),
      ];

      return [GroupItem(options: options), GroupItem(options: options1)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("Rule Set"),
            builder: (context) => GroupScreen(
                  title: "Rule Set",
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapGeoSite(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();
      var remoteConfig = RemoteConfigManager.getConfig();
      List<GroupItemOptions> options = [
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.enable,
                switchValue: settingConfig.ruleSets.enableGeoSite,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.enableGeoSite = value;
                  SettingManager.setDirty(true);
                })),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.SettingsScreen.useRomoteRes,
                switchValue: settingConfig.ruleSets.useRemoteGeoSite,
                tips: remoteConfig.geosite,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.useRemoteGeoSite = value;
                  SettingManager.setDirty(true);
                })),
      ];

      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("rulesetGeoSite"),
            builder: (context) => GroupScreen(
                  title: tcontext.rulesetGeoSite,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapGeoIP(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();
      var remoteConfig = RemoteConfigManager.getConfig();
      List<GroupItemOptions> options = [
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.enable,
                switchValue: settingConfig.ruleSets.enableGeoIp,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.enableGeoIp = value;
                  SettingManager.setDirty(true);
                })),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.SettingsScreen.useRomoteRes,
                switchValue: settingConfig.ruleSets.useRemoteGeoIp,
                tips: remoteConfig.geoip,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.useRemoteGeoIp = value;
                  SettingManager.setDirty(true);
                })),
      ];

      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("rulesetGeoIp"),
            builder: (context) => GroupScreen(
                  title: tcontext.rulesetGeoIp,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapAcl(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();
      var remoteConfig = RemoteConfigManager.getConfig();
      List<GroupItemOptions> options = [
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.enable,
                switchValue: settingConfig.ruleSets.enableAcl,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.enableAcl = value;
                  SettingManager.setDirty(true);
                })),
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.SettingsScreen.useRomoteRes,
                switchValue: settingConfig.ruleSets.useRemoteAcl,
                tips: remoteConfig.acl,
                onSwitch: (bool value) async {
                  settingConfig.ruleSets.useRemoteAcl = value;
                  SettingManager.setDirty(true);
                })),
      ];

      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("rulesetAcl"),
            builder: (context) => GroupScreen(
                  title: tcontext.rulesetAcl,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapRuleSetDirectDownload(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [];
      List<String> hosts = [];
      var remoteConfig = RemoteConfigManager.getConfig();
      List<String> geoUrls = [remoteConfig.geosite, remoteConfig.geoip];
      for (var url in geoUrls) {
        Uri? uri = Uri.tryParse(url);
        if (uri != null && uri.host.isNotEmpty && !hosts.contains(uri.host)) {
          hosts.add(uri.host);
        }
      }
      var rulesets = ServerManager.getDiversionGroupConfig().ruleSetItems;
      for (var rs in rulesets) {
        Uri? uri = Uri.tryParse(rs.url!);
        if (uri != null && uri.host.isNotEmpty && !hosts.contains(uri.host)) {
          hosts.add(uri.host);
        }
      }
      hosts.sort((a, b) => a.compareTo(b));
      for (var host in hosts) {
        options.add(GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: host,
                switchValue:
                    ServerManager.getUse().rulesetDirectDownload.contains(host),
                onSwitch: (bool value) async {
                  var use = ServerManager.getUse();
                  if (value) {
                    use.rulesetDirectDownload.add(host);
                  } else {
                    use.rulesetDirectDownload.remove(host);
                  }
                  ServerManager.setDirty(true);
                })));
      }
      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("rulesetDirectDownlad"),
            builder: (context) => GroupScreen(
                  title: tcontext.SettingsScreen.rulesetDirectDownlad,
                  getOptions: getOptions,
                )));
    if (ServerManager.getDirty()) {
      ServerManager.saveUse();
    }
  }

  static Future<void> showBackupAndSync(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        Platform.isIOS || Platform.isMacOS
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.iCloud,
                    onPush: () async {
                      onTapiCloud(context);
                    }))
            : GroupItemOptions(),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.webdav,
                onPush: () async {
                  onTapWebdav(context);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.BackupAndSyncLanSyncScreen.title,
                onPush: () async {
                  onTapLanSync(context);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.importAndExport,
                onPush: () async {
                  onTapImportExport(context);
                }))
      ];
      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("backupAndSync"),
            builder: (context) => GroupScreen(
                  title: tcontext.backupAndSync,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapiCloud(BuildContext context) async {
    Navigator.push(
        context,
        MaterialPageRoute(
            settings: BackupAndSyncIcloudScreen.routSettings(),
            builder: (context) => const BackupAndSyncIcloudScreen()));
  }

  static Future<void> onTapWebdav(BuildContext context) async {
    Navigator.push(
        context,
        MaterialPageRoute(
            settings: BackupAndSyncWebdavScreen.routSettings(),
            builder: (context) => const BackupAndSyncWebdavScreen()));
  }

  static Future<void> onTapLanSyncTo(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.qrcode,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: BackupAndSyncLanSyncScreen.routSettings(),
                          builder: (context) => BackupAndSyncLanSyncScreen(
                              title: tcontext.SettingsScreen.lanSyncTo,
                              syncUpload: false)));
                })),
        PlatformUtils.isMobile()
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.SettingsScreen.lanSyncScanQRcode,
                    onPush: () async {
                      onTapSyncByScanQRcode(context);
                    }))
            : GroupItemOptions(),
      ];
      return [GroupItem(options: options)];
    }

    if (!context.mounted) {
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("lanSyncTo"),
            builder: (context) => GroupScreen(
                  title: tcontext.SettingsScreen.lanSyncTo,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapLanSyncFrom(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.qrcode,
                onPush: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: BackupAndSyncLanSyncScreen.routSettings(),
                          builder: (context) => BackupAndSyncLanSyncScreen(
                              title: tcontext.SettingsScreen.lanSyncFrom,
                              syncUpload: true)));
                })),
        PlatformUtils.isMobile()
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.SettingsScreen.lanSyncScanQRcode,
                    onPush: () async {
                      onTapSyncByScanQRcode(context);
                    }))
            : GroupItemOptions(),
      ];
      return [GroupItem(options: options)];
    }

    if (!context.mounted) {
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("lanSyncFrom"),
            builder: (context) => GroupScreen(
                  title: tcontext.SettingsScreen.lanSyncFrom,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapLanSync(BuildContext context) async {
    final tcontext = Translations.of(context);
    bool canzip = await ServerManager.canZip();
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.lanSyncTo,
                onPush: !canzip
                    ? null
                    : () async {
                        onTapLanSyncTo(context);
                      })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.lanSyncFrom,
                onPush: () async {
                  onTapLanSyncFrom(context);
                })),
      ];
      return [GroupItem(options: options)];
    }

    if (!context.mounted) {
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("BackupAndSyncLanSyncScreen"),
            builder: (context) => GroupScreen(
                  title: tcontext.BackupAndSyncLanSyncScreen.title,
                  getOptions: getOptions,
                )));
  }

  static Future<void> backupRestoreFromZip(BuildContext context, String zipPath,
      {bool confirm = false}) async {
    if (!context.mounted) {
      return;
    }
    final tcontext = Translations.of(context);
    bool? ok = true;
    if (confirm) {
      ok = await DialogUtils.showConfirmDialog(
          context, tcontext.SettingsScreen.rewriteConfirm);
    }

    if (ok == true) {
      var error = await ServerManager.reloadFromZip(zipPath);
      if (!context.mounted) {
        return;
      }
      if (error != null) {
        DialogUtils.showAlertDialog(context, error.message);
      } else {
        DialogUtils.showAlertDialog(
            context, tcontext.SettingsScreen.importSuccess);
      }
    }
  }

  static Future<void> syncByScanQRcode(
      BuildContext context, String qrcode) async {
    final tcontext = Translations.of(context);
    if (qrcode.isEmpty) {
      return;
    }
    Uri? uri = Uri.tryParse(qrcode);
    if (uri == null || uri.scheme != AppSchemeUtils.scheme()) {
      return;
    }

    if (uri.host != AppSchemeUtils.syncDownloadAction() &&
        uri.host != AppSchemeUtils.syncUploadAction()) {
      return;
    }

    String ips = uri.queryParameters['ips'] ?? '';
    String port = uri.queryParameters['port'] ?? '';
    String filename = uri.queryParameters['filename'] ?? '';
    if (ips.isEmpty || port.isEmpty) {
      return;
    }
    List<String> hosts = ips.split(",");
    int iPort = int.parse(port);
    String? targetHost;
    ReturnResult<int>? result;
    for (String host in hosts) {
      if (host.isNotEmpty) {
        result = await NetworkUtils.testConnectLatency(host, iPort, null);
        if (result.error == null) {
          targetHost = host;
          break;
        }
      }
    }
    if (!context.mounted) {
      return;
    }
    if (targetHost == null) {
      if (result != null && result.error != null) {
        DialogUtils.showAlertDialog(
            context, tcontext.targetConnectFailed(p: result.error!.message));
      } else {
        DialogUtils.showAlertDialog(
            context, tcontext.targetConnectFailed(p: ips));
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (uri.host == AppSchemeUtils.syncDownloadAction()) {
      if (filename.isEmpty) {
        return;
      }

      bool? ok = await DialogUtils.showConfirmDialog(
          context, tcontext.SettingsScreen.rewriteConfirm);
      if (ok != true) {
        return;
      }
      String dir = await PathUtils.cacheDir();
      String zipPath = path.join(dir, filename);
      String url = "http://$targetHost:$iPort/${uri.host}";
      var result = await HttpUtils.httpDownload(
          Uri.parse(url), zipPath, null, null, null);
      if (result.error != null) {
        if (!context.mounted) {
          return;
        }
        DialogUtils.showAlertDialog(context, result.error.toString(),
            showCopy: true, withVersion: true);
        return;
      }
      if (!context.mounted) {
        return;
      }
      await backupRestoreFromZip(context, zipPath, confirm: false);
    } else if (uri.host == AppSchemeUtils.syncUploadAction()) {
      bool? ok = await DialogUtils.showConfirmDialog(
          context, tcontext.SettingsScreen.syncToConfirm);
      if (ok != true) {
        return;
      }
      String dir = await PathUtils.cacheDir();
      String zipPath = path.join(dir, BackupAndSyncUtils.getZipFileName());
      var error = await ServerManager.backupToZip(zipPath);
      if (error != null) {
        if (!context.mounted) {
          return;
        }
        DialogUtils.showAlertDialog(context, error.toString(),
            showCopy: true, withVersion: true);
        return;
      }
      String url = "http://$targetHost:$iPort/${uri.host}";
      var err = await HttpUtils.httpUpload(Uri.parse(url), zipPath, null, null);
      FileUtils.deleteFileByPath(zipPath);
      if (!context.mounted) {
        return;
      }
      if (err != null) {
        DialogUtils.showAlertDialog(context, err.message);
      } else {
        DialogUtils.showAlertDialog(context, tcontext.SettingsScreen.syncDone);
      }
    }
  }

  static Future<void> onTapSyncByScanQRcode(BuildContext context) async {
    String? qrcode = await Navigator.push(
        context,
        MaterialPageRoute(
            settings: QrcodeScanScreen.routSettings(),
            builder: (context) => const QrcodeScanScreen()));
    if (!context.mounted) {
      return;
    }
    await syncByScanQRcode(context, qrcode ?? "");
  }

  static Future<void> showAppleTVByScanQRCode(BuildContext context) async {
    if (!PlatformUtils.isMobile()) {
      return;
    }
    String? qrcode = await Navigator.push(
        context,
        MaterialPageRoute(
            settings: QrcodeScanScreen.routSettings(),
            builder: (context) => const QrcodeScanScreen()));
    if (qrcode == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    return await showAppleTVByUrl(context, qrcode);
  }

  static Future<void> showAppleTVByUrl(
      BuildContext context, String qrcode) async {
    final tcontext = Translations.of(context);
    var settingConfig = SettingManager.getConfig();
    if (!settingConfig.privateDirect) {
      bool started = await VPNService.started();
      if (!context.mounted) {
        return;
      }
      if (started) {
        DialogUtils.showAlertDialog(
            context, tcontext.appleTVConnectTurnOfprivateDirect);
        return;
      }
    }

    Uri? uri = Uri.tryParse(qrcode);
    if (uri == null || uri.host != AppSchemeUtils.appleTVHost()) {
      DialogUtils.showAlertDialog(context, tcontext.appleTVUrlInvalid);
      return;
    }
    String ips = uri.queryParameters['ips'] ?? '';
    String port = uri.queryParameters['port'] ?? '';
    String uuid = uri.queryParameters['uuid'] ?? '';
    String version = uri.queryParameters['version'] ?? '';
    String cport = uri.queryParameters['cport'] ?? '';
    String secret = uri.queryParameters['secret'] ?? '';
    if (ips.isEmpty) {
      DialogUtils.showAlertDialog(context,
          "${tcontext.urlInvalid}: params [ips] is empty, Please make sure that your Apple TV is connected to the Internet.");
      return;
    }
    if (port.isEmpty) {
      DialogUtils.showAlertDialog(
          context, "${tcontext.urlInvalid}: params [port] is empty");
      return;
    }
    if (version.isEmpty) {
      DialogUtils.showAlertDialog(
          context, "${tcontext.urlInvalid}: params [version] is empty");
      return;
    }
    if (secret.isEmpty) {
      secret = Did.newUUID();
    }

    List<String> hosts = ips.split(",");
    int targetPort = int.parse(port);
    String? targetHost;
    ReturnResult<int>? result;
    for (String host in hosts) {
      if (host.isNotEmpty) {
        result = await NetworkUtils.testConnectLatency(host, targetPort, null);
        if (result.error == null) {
          targetHost = host;
          break;
        }
      }
    }
    if (!context.mounted) {
      return;
    }
    if (targetHost == null) {
      if (result != null && result.error != null) {
        DialogUtils.showAlertDialog(
            context, tcontext.targetConnectFailed(p: result.error!.message));
      } else {
        DialogUtils.showAlertDialog(
            context, tcontext.targetConnectFailed(p: ips));
      }

      return;
    }
    AnalyticsUtils.logEvent(
      analyticsEventType: analyticsEventTypeUA,
      name: 'appletv',
    );
    Navigator.push(
        context,
        MaterialPageRoute(
            settings: HomeTVOSScreen.routSettings(),
            builder: (context) => HomeTVOSScreen(
                host: targetHost!,
                port: targetPort,
                cport: cport,
                uuid: uuid,
                secret: secret)));
  }

  static Future<void> onTapImportExport(BuildContext context) async {
    final tcontext = Translations.of(context);
    bool canzip = await ServerManager.canZip();
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.import,
                onPush: () async {
                  onTapImport(context);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.export,
                onPush: !canzip
                    ? null
                    : () async {
                        onTapExport(context);
                      })),
      ];
      return [GroupItem(options: options)];
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("importAndExport"),
            builder: (context) => GroupScreen(
                  title: tcontext.importAndExport,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapImport(BuildContext context) async {
    final tcontext = Translations.of(context);
    List<String> extensions = [BackupAndSyncUtils.getZipExtension()];
    try {
      FilePickerResult? pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );
      if (!context.mounted) {
        return;
      }
      if (pickResult != null) {
        String filePath = pickResult.files.first.path!;
        String ext = path.extension(filePath).replaceAll('.', '').toLowerCase();
        if (!extensions.contains(ext)) {
          DialogUtils.showAlertDialog(
              context, tcontext.invalidFileType(p: ext));
          return;
        }
        if (!context.mounted) {
          return;
        }
        await GroupHelper.backupRestoreFromZip(context, filePath,
            confirm: true);
      }
    } catch (err, stacktrace) {
      if (!context.mounted) {
        return;
      }
      DialogUtils.showAlertDialog(context, err.toString());
    }
  }

  static Future<void> onTapExport(BuildContext context) async {
    try {
      String? filePath;
      if (PlatformUtils.isMobile()) {
        String dir = await PathUtils.cacheDir();
        filePath = path.join(dir, BackupAndSyncUtils.getZipFileName());
      } else {
        filePath = await FilePicker.platform.saveFile(
          fileName: BackupAndSyncUtils.getZipFileName(),
          lockParentWindow: true,
        );
      }

      if (filePath != null) {
        var error = await ServerManager.backupToZip(filePath);
        if (!context.mounted) {
          FileUtils.deleteFileByPath(filePath);
          return;
        }
        if (error != null) {
          DialogUtils.showAlertDialog(context, error.message);
        }
        if (PlatformUtils.isMobile()) {
          try {
            final box = context.findRenderObject() as RenderBox?;
            Share.shareXFiles([XFile(filePath)],
                sharePositionOrigin:
                    box!.localToGlobal(Offset.zero) & box.size);
          } catch (err) {}
        }
      }
    } catch (err, stacktrace) {
      if (!context.mounted) {
        return;
      }
      DialogUtils.showAlertDialog(context, err.toString());
    }
  }

  static Future<void> onTapDNSStaticIP(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();

      List<GroupItemOptions> options = [
        GroupItemOptions(
            switchOptions: GroupItemSwitchOptions(
                name: tcontext.enable,
                switchValue: settingConfig.dns.enableStaticIP,
                onSwitch: (bool value) async {
                  settingConfig.dns.enableStaticIP = value;
                  SettingManager.setDirty(true);
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.staticIP,
                onPush: () async {
                  String oldData = settingConfig.dns.staticIPs.toString();
                  List<Tuple2<String, List<String>>> hs = [];
                  settingConfig.dns.staticIPs.forEach((key, value) {
                    hs.add(Tuple2(key, value));
                  });

                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: MapListAddScreen.routSettings(),
                          builder: (context) => MapListAddScreen(
                              title: tcontext.staticIP,
                              data: hs,
                              dialogTitle1: tcontext.domain,
                              dialogTextHit1: "google.com",
                              dialogTitle2: tcontext.ip,
                              dialogTextHit2: "93.46.8.90")));

                  settingConfig.dns.staticIPs.clear();
                  for (var h in hs) {
                    settingConfig.dns.staticIPs[h.item1] = h.item2;
                  }

                  String newData = settingConfig.dns.staticIPs.toString();
                  if (oldData != newData) {
                    settingConfig.dns.staticIPs.forEach((key, value) {
                      value.removeWhere((ele) {
                        return !NetworkUtils.isIpv4(ele) &&
                            !NetworkUtils.isIpv6(ele);
                      });
                    });
                    settingConfig.dns.staticIPs.removeWhere((key, value) {
                      return !NetworkUtils.isDomain(key, false);
                    });
                    SettingManager.setDirty(true);
                  }
                })),
      ];

      return [GroupItem(options: options)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("staticIP"),
            builder: (context) => GroupScreen(
                  title: tcontext.staticIP,
                  getOptions: getOptions,
                )));
  }

  static Future<void> onTapDNSServer(BuildContext context) async {
    final tcontext = Translations.of(context);
    Future<List<GroupItem>> getOptions(BuildContext context) async {
      var settingConfig = SettingManager.getConfig();
      bool tunMode = await VPNService.getTunMode();

      String regionCode = settingConfig.regionCode.toLowerCase();
      var resolver = settingConfig.dns.getResolverDns(regionCode, tunMode);
      var outbound = settingConfig.dns.getOutboundDns(regionCode, tunMode);
      var direct = settingConfig.dns.getDirectDns(regionCode, tunMode);
      var proxy = settingConfig.dns.getProxyDns(regionCode, tunMode);
      var final_ = settingConfig.dns.getFinalDns(regionCode, tunMode);
      List<GroupItemOptions> options = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.dnsTypeResolver,
                tips: tcontext.SettingsScreen.dnsTypeResolverTips,
                text: resolver.length == 1 ? resolver[0] : "${resolver[0]}...",
                textWidthPercent: 0.5,
                onPush: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DnsSettingsScreen.routSettings(),
                          builder: (context) => DnsSettingsScreen(
                              title: tcontext.SettingsScreen.dnsTypeResolver,
                              dnsType: DNSType.dnsTypeResolver)));
                })),
        !settingConfig.novice
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.SettingsScreen.dnsTypeOutbound,
                    tips: tcontext.SettingsScreen.dnsTypeOutboundTips,
                    text: outbound.length == 1
                        ? outbound[0]
                        : "${outbound[0]}...",
                    onPush: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              settings: DnsSettingsScreen.routSettings(),
                              builder: (context) => DnsSettingsScreen(
                                  title:
                                      tcontext.SettingsScreen.dnsTypeOutbound,
                                  dnsType: DNSType.dnsTypeOutbound)));
                    }))
            : GroupItemOptions(),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.dnsTypeDirect,
                tips: tcontext.SettingsScreen.dnsTypeDirectTips,
                text: direct.length == 1 ? direct[0] : "${direct[0]}...",
                textWidthPercent: 0.5,
                onPush: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DnsSettingsScreen.routSettings(),
                          builder: (context) => DnsSettingsScreen(
                              title: tcontext.SettingsScreen.dnsTypeDirect,
                              dnsType: DNSType.dnsTypeDirect)));
                })),
        !settingConfig.novice
            ? GroupItemOptions(
                pushOptions: GroupItemPushOptions(
                    name: tcontext.SettingsScreen.dnsTypeProxy,
                    tips: tcontext.SettingsScreen.dnsTypeProxyTips,
                    text: proxy.length == 1 ? proxy[0] : "${proxy[0]}...",
                    textWidthPercent: 0.5,
                    onPush: !settingConfig.dns.enableRule ||
                            settingConfig.dns.enableFakeIp
                        ? null
                        : () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    settings: DnsSettingsScreen.routSettings(),
                                    builder: (context) => DnsSettingsScreen(
                                        title: tcontext
                                            .SettingsScreen.dnsTypeProxy,
                                        dnsType: DNSType.dnsTypeProxy)));
                          }))
            : GroupItemOptions(),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.routeFinal,
                tips: tcontext.SettingsScreen.dnsTypeFinalTips,
                text: final_.length == 1 ? final_[0] : "${final_[0]}...",
                textWidthPercent: 0.5,
                onPush: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DnsSettingsScreen.routSettings(),
                          builder: (context) => DnsSettingsScreen(
                              title: tcontext.routeFinal,
                              dnsType: DNSType.dnsTypeFinal)));
                })),
      ];
      List<GroupItemOptions> options1 = [
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.dnsAutoSetServer,
                onPush: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: DnsAutoSetupScreen.routSettings(),
                          builder: (context) => const DnsAutoSetupScreen()));
                })),
        GroupItemOptions(
            pushOptions: GroupItemPushOptions(
                name: tcontext.SettingsScreen.dnsResetServer,
                onPush: () async {
                  settingConfig.dns.setOutboundDns([]);
                  settingConfig.dns.setDirectDns([]);
                  settingConfig.dns.setProxyDns([]);
                  settingConfig.dns.setResolverDns([]);
                  settingConfig.dns.setFinalDns([]);
                  SettingManager.setDirty(true);
                })),
      ];

      return [GroupItem(options: options), GroupItem(options: options1)];
    }

    await Navigator.push(
        context,
        MaterialPageRoute(
            settings: GroupScreen.routSettings("server"),
            builder: (context) => GroupScreen(
                  title: tcontext.server,
                  getOptions: getOptions,
                )));
  }
}