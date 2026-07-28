// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '收支本';

  @override
  String get recordTab => '记账';

  @override
  String get transactionsTab => '明细';

  @override
  String get statisticsTab => '统计';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get amount => '金额';

  @override
  String get takePhoto => '拍摄小票';

  @override
  String get choosePhoto => '从相册选择';

  @override
  String get photoRecord => '小票照片';

  @override
  String get photoPreviewTitle => '已选择小票';

  @override
  String get photoPreviewMessage => '自动识别功能将在下一阶段开放。现在可以改为手动填写这笔账。';

  @override
  String get continueManually => '手动填写';

  @override
  String get close => '关闭';

  @override
  String get cameraUnavailable => '相机或相册暂时不可用。';

  @override
  String get category => '分类';

  @override
  String get food => '餐饮';

  @override
  String get transport => '交通';

  @override
  String get shopping => '购物';

  @override
  String get housing => '住房';

  @override
  String get other => '其他';

  @override
  String get incomeCategory => '收入';

  @override
  String get date => '日期';

  @override
  String get note => '备注（可选）';

  @override
  String get saveTransaction => '保存这笔账';

  @override
  String get invalidAmount => '请输入大于 \$0 的金额。';

  @override
  String get saved => '保存成功';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String dailyIncome(String amount) {
    return '收入 $amount';
  }

  @override
  String dailyExpense(String amount) {
    return '支出 $amount';
  }

  @override
  String dailyBalance(String amount) {
    return '结余 $amount';
  }

  @override
  String get noTransactions => '这个月还没有账目';

  @override
  String get noTransactionsHint => '记录第一笔收支后，会显示在这里。';

  @override
  String get recordOne => '去记一笔';

  @override
  String get delete => '删除';

  @override
  String get deleted => '账目已删除';

  @override
  String get undo => '撤销';

  @override
  String get editTransaction => '编辑账目';

  @override
  String get cancel => '取消';

  @override
  String get saveChanges => '保存修改';

  @override
  String get monthlyOverview => '本月概览';

  @override
  String get totalIncome => '收入';

  @override
  String get totalExpense => '支出';

  @override
  String get balance => '结余';

  @override
  String get expenseBreakdown => '支出分类';

  @override
  String get noExpenses => '这个月还没有支出';

  @override
  String get noExpensesHint => '记录支出后，这里会显示分类占比。';

  @override
  String chartSummary(String summary) {
    return '支出分类：$summary';
  }

  @override
  String percentage(String value) {
    return '$value%';
  }

  @override
  String get loading => '正在加载…';
}
