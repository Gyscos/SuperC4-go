library app_bootstrap;

import 'package:polymer/polymer.dart';

import 'package:core_elements/core_toolbar.dart' as i0;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_media_query.dart' as i1;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_selection.dart' as i2;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_selector.dart' as i3;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_drawer_panel.dart' as i4;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_header_panel.dart' as i5;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_meta.dart' as i6;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_iconset.dart' as i7;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_icon.dart' as i8;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_iconset_svg.dart' as i9;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_icon_button.dart' as i10;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_scaffold.dart' as i11;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_menu.dart' as i12;
import 'package:polymer/src/build/log_injector.dart';
import 'package:core_elements/core_item.dart' as i13;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_ripple.dart' as i14;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_radio_button.dart' as i15;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_radio_group.dart' as i16;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_focusable.dart' as i17;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_shadow.dart' as i18;
import 'package:polymer/src/build/log_injector.dart';
import 'package:paper_elements/paper_button.dart' as i19;
import 'package:polymer/src/build/log_injector.dart';
import 'canvas.dart' as i20;
import 'package:polymer/src/build/log_injector.dart';
import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;

void main() {
  useGeneratedCode(new StaticConfiguration(
      checkedMode: false,
      getters: {
        #blurAction: (o) => o.blurAction,
        #checked: (o) => o.checked,
        #contextMenuAction: (o) => o.contextMenuAction,
        #downAction: (o) => o.downAction,
        #dragging: (o) => o.dragging,
        #drawerWidth: (o) => o.drawerWidth,
        #focusAction: (o) => o.focusAction,
        #icon: (o) => o.icon,
        #iconSrc: (o) => o.iconSrc,
        #label: (o) => o.label,
        #mode: (o) => o.mode,
        #multi: (o) => o.multi,
        #narrow: (o) => o.narrow,
        #queryMatches: (o) => o.queryMatches,
        #raisedButton: (o) => o.raisedButton,
        #responsiveWidth: (o) => o.responsiveWidth,
        #rightDrawer: (o) => o.rightDrawer,
        #selected: (o) => o.selected,
        #selectionSelect: (o) => o.selectionSelect,
        #src: (o) => o.src,
        #togglePanel: (o) => o.togglePanel,
        #tokenList: (o) => o.tokenList,
        #transition: (o) => o.transition,
        #upAction: (o) => o.upAction,
        #z: (o) => o.z,
      },
      setters: {
        #icon: (o, v) { o.icon = v; },
        #iconSrc: (o, v) { o.iconSrc = v; },
        #mode: (o, v) { o.mode = v; },
        #multi: (o, v) { o.multi = v; },
        #narrow: (o, v) { o.narrow = v; },
        #queryMatches: (o, v) { o.queryMatches = v; },
        #responsiveWidth: (o, v) { o.responsiveWidth = v; },
        #selected: (o, v) { o.selected = v; },
        #src: (o, v) { o.src = v; },
        #z: (o, v) { o.z = v; },
      },
      names: {
        #blurAction: r'blurAction',
        #checked: r'checked',
        #contextMenuAction: r'contextMenuAction',
        #downAction: r'downAction',
        #dragging: r'dragging',
        #drawerWidth: r'drawerWidth',
        #focusAction: r'focusAction',
        #icon: r'icon',
        #iconSrc: r'iconSrc',
        #label: r'label',
        #mode: r'mode',
        #multi: r'multi',
        #narrow: r'narrow',
        #queryMatches: r'queryMatches',
        #raisedButton: r'raisedButton',
        #responsiveWidth: r'responsiveWidth',
        #rightDrawer: r'rightDrawer',
        #selected: r'selected',
        #selectionSelect: r'selectionSelect',
        #src: r'src',
        #togglePanel: r'togglePanel',
        #tokenList: r'tokenList',
        #transition: r'transition',
        #upAction: r'upAction',
        #z: r'z',
      }));
  new LogInjector().injectLogsFromUrl('superc4_ui.html._buildLogs');
  configureForDeployment([
      i0.upgradeCoreToolbar,
      i1.upgradeCoreMediaQuery,
      i2.upgradeCoreSelection,
      i3.upgradeCoreSelector,
      i4.upgradeCoreDrawerPanel,
      i5.upgradeCoreHeaderPanel,
      i6.upgradeCoreMeta,
      i7.upgradeCoreIconset,
      i8.upgradeCoreIcon,
      i9.upgradeCoreIconsetSvg,
      i10.upgradeCoreIconButton,
      i11.upgradeCoreScaffold,
      i12.upgradeCoreMenu,
      i13.upgradeCoreItem,
      i14.upgradePaperRipple,
      i15.upgradePaperRadioButton,
      i16.upgradePaperRadioGroup,
      i17.upgradePaperFocusable,
      i18.upgradePaperShadow,
      i19.upgradePaperButton,
    ]);
  i20.main();
}
