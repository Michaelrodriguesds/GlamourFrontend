# Changelog — Glamour Agenda Frontend

## Versão atual — Mudanças aplicadas

### Novas funcionalidades

#### Agendamento duplo no mesmo horário
- `data/models/availability_model.dart`
  - `TimeSlot` agora tem `List<AppointmentInfo> appointments` (suporta 1 ou 2)
  - Campos `occupancy` e `maxCapacity`
  - Backward-compat com formato antigo (`appointment` objeto único)
- `presentation/screens/calendar/day_slots_widget.dart`
  - Slot com **2 agendamentos** exibe ambos empilhados lado a lado
  - Barra lateral bicolor (cor de cada cliente)
  - Badge "2×" no horário quando duplo
  - Toque individual em cada cliente do slot

#### Gráfico de fluxo anual de demanda (Tela de Estatísticas)
- `presentation/screens/stats/stats_screen.dart`
  - Novo widget `_YearTrendChart` com gráfico de barras interativo (`fl_chart`)
  - Barra de pico em rose, baixa em lavanda, demais em rose suave
  - Toque na barra = tooltip com mês, atendimentos e receita
  - Badge de pico (🔥) e baixa (📉) no cabeçalho
  - Legenda de cores
- `data/models/stats_model.dart` — `MonthTrend` e `YearTrend` adicionados
- `data/services/stats_service.dart` — `getYearTrend(year)` adicionado
- `core/constants/api_endpoints.dart` — `trendStats` adicionado

### Infraestrutura e resiliência

#### Refresh token silencioso
- `data/services/api_service.dart`
  - Interceptor Dio que tenta `POST /api/auth/refresh` ao receber 401
  - Repete a requisição original automaticamente com o novo token
  - Somente faz logout se o refresh também falhar
- `core/constants/api_endpoints.dart` — `refreshToken` adicionado

#### Cache local com SharedPreferences
- `data/services/cache_service.dart` — TTL configurável por tipo de dado
  - Agendamentos: 60 min
  - Disponibilidade do mês: 15 min
  - Disponibilidade do dia: 10 min
  - Estatísticas: 30 min
  - Tendência anual: 2h
- Fallback automático para cache quando sem internet

#### Detecção de offline
- `data/services/connectivity_service.dart` — singleton com stream
- `providers/connectivity_provider.dart` — StateNotifier reativo
- `presentation/widgets/offline_banner.dart` — banner animado no topo
  - Aparece/some com `AnimatedContainer` (300ms)
  - `CacheBadge` para mostrar "salvo há X min"
- `main.dart` — `OfflineBanner` integrado acima do conteúdo principal

#### Fila offline (agendamentos sem internet)
- `data/services/offline_queue_service.dart`
  - `enqueueCreate`, `enqueueUpdate`, `enqueueDelete`
  - `sync()` — envia ao voltar online, até 5 retentativas por ação
  - Persiste em SharedPreferences (sobrevive ao restart do app)
- `providers/appointments_provider.dart`
  - Cria/edita/apaga otimisticamente na UI quando offline
  - Escuta `ConnectivityService.onStatusChange` e sincroniza automaticamente
  - `pendingSyncCount` exposto no estado para mostrar badge

### Arquivos novos/modificados
| Arquivo | O que mudou |
|---|---|
| `main.dart` | Init de CacheService e ConnectivityService, OfflineBanner no shell |
| `data/models/availability_model.dart` | TimeSlot com lista de agendamentos |
| `data/models/stats_model.dart` | +MonthTrend, +YearTrend |
| `data/services/api_service.dart` | Refresh token silencioso no interceptor |
| `data/services/cache_service.dart` | Cache completo com TTL e fallback |
| `data/services/connectivity_service.dart` | Monitoramento de internet |
| `data/services/offline_queue_service.dart` | Fila persistente offline |
| `data/services/stats_service.dart` | +getYearTrend |
| `providers/appointments_provider.dart` | Cache + offline + sync automático |
| `providers/availability_provider.dart` | Cache com TTL curto (15 min) |
| `providers/connectivity_provider.dart` | StateNotifier reativo |
| `providers/stats_provider.dart` | Cache + fallback offline |
| `presentation/screens/calendar/day_slots_widget.dart` | Slot duplo visual |
| `presentation/screens/stats/stats_screen.dart` | Gráfico anual |
| `presentation/widgets/offline_banner.dart` | Banner animado + CacheBadge |
| `core/constants/api_endpoints.dart` | +refreshToken, +trendStats |
| `pubspec.yaml` | connectivity_plus, shared_preferences já incluídos |

### O que ainda precisa de ação manual (3 passos)
1. `flutter pub get` — instalar pacotes novos
2. No Render: configurar `healthCheckPath: /health` no painel (ou deploy do render.yaml)
3. No Atlas: não precisa fazer nada — maxPoolSize está no código
