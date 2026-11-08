import 'dart:io';

import 'package:idle_orbit/game/config/balance_config.dart';

BalanceConfig loadBalance() =>
    BalanceConfig.fromJsonString(File('assets/config/balance.json').readAsStringSync());

const t0 = 1700000000000; // fixed epoch ms for deterministic tests
const hourMs = 3600 * 1000;
