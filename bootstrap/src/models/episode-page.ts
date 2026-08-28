import { CharacterMilestone } from './character-milestone.js'
import { Episode } from './episode.js'

export type EpisodePage = {
    info: Episode
    milestones: CharacterMilestone[]
}
