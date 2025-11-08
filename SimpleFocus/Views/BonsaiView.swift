//
//  BonsaiView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI
import UIKit

struct BonsaiView: View {
    @ObservedObject var controller: BonsaiController
    @AppStorage("hasNewBonsaiGrowth") private var hasNewBonsaiGrowth: Bool = false

    private let stages: [BonsaiStage] = [
        .init(range: 0...2,
              imageName: "bonsai1",
              title: "初芽",
              message: "坚持完成任务，嫩芽将逐渐长高。"),
        .init(range: 3...7,
              imageName: "bonsai12",
              title: "幼苗",
              message: "幼苗开始舒展枝叶，保持良好势头。"),
        .init(range: 8...15,
              imageName: "bonsai13",
              title: "成长期",
              message: "枝干更稳固，专注力也更强大。"),
        .init(range: 16...30,
              imageName: "bonsai14",
              title: "成长树形",
              message: "已经具备明显的树形，继续呵护。"),
        .init(range: 31...50,
              imageName: "bonsai15",
              title: "繁茂期",
              message: "枝叶繁茂，专注成果令人欣喜。"),
        .init(range: 51...Int.max,
              imageName: "bonsai16",
              title: "臻于成熟",
              message: "专注盆景已成为你日常的一部分。")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                artwork
                growthSummary
                tipsCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 48)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            hasNewBonsaiGrowth = false
        }
        .navigationTitle("专注盆景")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("我的专注盆景")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("已连续专注 \(controller.bonsai.growthPoints) 天")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var artwork: some View {
        VStack(spacing: 16) {
            bonsaiImage(for: controller.bonsai.growthPoints)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(AppTheme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(AppTheme.surfaceMuted, lineWidth: 1)
                )

            Text(currentStage.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text(currentStage.message)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    private var growthSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成长轨迹")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: 16) {
                summaryItem(title: "成长值",
                            value: "\(controller.bonsai.growthPoints) 天")
                summaryItem(title: "下一阶段",
                            value: nextStageDescription)
            }

            ProgressView(value: progressTowardsNextStage)
                .progressViewStyle(.linear)
                .tint(AppTheme.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surfaceElevated)
        )
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("成长提示")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text("只要坚持完成当天所有任务，盆景就会迎来新的变化。它不会因为暂时的停顿而枯萎，请放轻松继续向前。")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surfaceMuted)
        )
    }

    @ViewBuilder
    private func bonsaiImage(for growthPoints: Int) -> some View {
        let imageName = bonsaiImageName(for: growthPoints)
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .padding(24)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                Text("缺少 \(imageName).png")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bonsaiImageName(for growthPoints: Int) -> String {
        switch growthPoints {
        case 0...2:
            return "bonsai1"
        case 3...7:
            return "bonsai12"
        case 8...15:
            return "bonsai13"
        case 16...30:
            return "bonsai14"
        case 31...50:
            return "bonsai15"
        default:
            return "bonsai16"
        }
    }

    private var currentStage: BonsaiStage {
        stages.first { $0.contains(controller.bonsai.growthPoints) } ?? stages.last!
    }

    private var progressTowardsNextStage: Double {
        guard let nextThreshold = currentStage.upperBoundInclusive else {
            return 1.0
        }
        let lower = currentStage.lowerBound
        let progress = Double(controller.bonsai.growthPoints - lower)
        let span = Double(nextThreshold - lower + 1)
        return min(max(progress / span, 0), 1)
    }

    private var nextStageDescription: String {
        guard let nextStage = stages.first(where: {
            $0.lowerBound > controller.bonsai.growthPoints
        }) else {
            return "已达最高阶段"
        }
        let remaining = max(0, nextStage.lowerBound - controller.bonsai.growthPoints)
        return "再坚持 \(remaining) 天"
    }
}

private struct BonsaiStage {
    let range: ClosedRange<Int>
    let imageName: String
    let title: String
    let message: String

    var lowerBound: Int { range.lowerBound }
    var upperBoundInclusive: Int? {
        range.upperBound == Int.max ? nil : range.upperBound
    }

    func contains(_ value: Int) -> Bool {
        range.contains(value)
    }
}

#Preview {
    let container = try! ModelContainer(for: TaskItem.self, Bonsai.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let controller = BonsaiController(modelContext: container.mainContext)
    controller.bonsai.growthPoints = 10
    return BonsaiView(controller: controller)
        .modelContainer(container)
}
